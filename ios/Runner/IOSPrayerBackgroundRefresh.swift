import Foundation
import BackgroundTasks
import UIKit

final class IOSPrayerBackgroundRefresh {
  static let shared = IOSPrayerBackgroundRefresh()
  static let identifier = "com.aw.huda.prayerNotifications.refresh"
  private var registered = false
  private let diagnostics = IOSPrayerBackgroundDiagnostics.shared
  var refreshLocation: (@MainActor () async -> Void)?
  private init() {}
  func register() {
    guard !registered else { return }
    registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.identifier, using: nil) { task in
      guard let refresh = task as? BGAppRefreshTask else { task.setTaskCompleted(success: false); return }
      self.run(refresh)
    }
    diagnostics.record("registered", success: registered)
    if !registered { Task { try? await IOSPrayerService.shared.backgroundError("backgroundRegistrationFailed") } }
  }
  func submit(coverage: Date? = nil, runID: String? = nil, label: String? = nil) {
    let request = BGAppRefreshTaskRequest(identifier: Self.identifier)
    let lowCoverage = coverage.map { $0.timeIntervalSinceNow < 3 * 86400 } ?? false
    request.earliestBeginDate = Date().addingTimeInterval(lowCoverage ? 3600 : 6 * 3600)
    do {
      // The same service renews prayer and Sahur occurrences.
      BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.identifier)
      try BGTaskScheduler.shared.submit(request)
      diagnostics.record("submitted", runID: runID, label: label, earliestBegin: request.earliestBeginDate, success: true)
    } catch {
      diagnostics.record("submissionFailed", runID: runID, label: label, earliestBegin: request.earliestBeginDate, success: false, error: "backgroundSubmissionFailed")
      Task { try? await IOSPrayerService.shared.backgroundError("backgroundSubmissionFailed") }
    }
  }
  private func run(_ task: BGAppRefreshTask) {
    let runID = UUID().uuidString
    let label = IOSPrayerBackgroundDiagnostics.validationLabel
    diagnostics.record("started", runID: runID, label: label)
    submit(runID: runID, label: label)
    let completion = IOSPrayerBackgroundCompletion { success in
      self.diagnostics.record("completed", runID: runID, label: label, success: success)
      task.setTaskCompleted(success: success)
    }
    let work = Task {
      do {
        let runtime = await MainActor.run { () -> (String, String) in
          let app = UIApplication.shared
          let state = app.applicationState == .background ? "background" : app.applicationState == .active ? "active" : "inactive"
          let refresh = app.backgroundRefreshStatus == .available ? "available" : app.backgroundRefreshStatus == .denied ? "denied" : "restricted"
          return (state, refresh)
        }
        try Task.checkCancellation()
        let before = try await IOSPrayerService.shared.status()
        diagnostics.record("queueBefore", runID: runID, label: label,
          applicationState: runtime.0, backgroundRefresh: runtime.1,
          lowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled, status: before)
        await refreshLocation?()
        try Task.checkCancellation()
        let status = try await IOSPrayerService.shared.reconcile()
        try Task.checkCancellation()
        diagnostics.record("queueAfter", runID: runID, label: label, status: status)
        let coverage = (status["coverageMillis"] as? Double).map { Date(timeIntervalSince1970: $0 / 1000) }
        submit(coverage: coverage, runID: runID, label: label)
        try? await IOSPrayerService.shared.backgroundError(nil)
        if !completion.finish(status["error"] is NSNull) {
          diagnostics.record("completionIgnored", runID: runID, label: label)
        }
      } catch {
        let category = error is CancellationError ? "backgroundExpired" : "backgroundRefreshFailed"
        diagnostics.record("workFailed", runID: runID, label: label, success: false, error: category)
        try? await IOSPrayerService.shared.backgroundError(category)
        if !completion.finish(false) { diagnostics.record("completionIgnored", runID: runID, label: label) }
      }
    }
    task.expirationHandler = {
      self.diagnostics.record("expired", runID: runID, label: label)
      work.cancel()
      if !completion.finish(false) { self.diagnostics.record("completionIgnored", runID: runID, label: label) }
    }
  }
}
