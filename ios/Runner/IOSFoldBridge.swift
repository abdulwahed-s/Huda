import Flutter
import UIKit

/// Reports the iPhone Duo's fold and inner camera to Flutter, which doesn't
/// populate `MediaQuery.displayFeatures` on iOS yet (flutter/flutter#192515).
///
/// iOS 27.1 describes them as reserved regions on a view: `.division` where
/// content should split in two (the fold) and `.occlusion` where hardware
/// covers the screen (the inner camera). A transparent probe view pinned to
/// the Flutter view re-reads them on every layout pass, and a hinge
/// interaction on it reports the posture. Dart turns the payload into
/// `DisplayFeature`s at the app root (`lib/core/services/ios_fold_bridge.dart`).
///
/// It takes a plugin registrar rather than a view controller so it works with
/// the app-delegate window today and with the UIScene lifecycle, where the
/// Flutter view only exists once a scene connects: it attaches to
/// `registrar.viewController` at creation if there is one, and otherwise
/// when Dart first asks for the state.
@MainActor
final class IOSFoldBridge {
  private let channel: FlutterMethodChannel
  private weak var registrar: FlutterPluginRegistrar?
  private weak var hostView: UIView?
  private var hinge: [String: Any]?
  private var lastState: NSDictionary?

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    channel = FlutterMethodChannel(
      name: "com.aw.huda/fold",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "getState" else {
        result(FlutterMethodNotImplemented)
        return
      }
      MainActor.assumeIsolated {
        guard let self else {
          result(nil)
          return
        }
        self.attachIfNeeded()
        let state = self.state()
        self.lastState = state as NSDictionary
        result(state)
      }
    }
    attachIfNeeded()
  }

  private func attachIfNeeded() {
    #if compiler(>=6.4)
      guard #available(iOS 27.1, *), hostView == nil,
        let view = registrar?.viewController?.view
      else { return }
      hostView = view
      let probe = FoldProbeView(frame: view.bounds)
      probe.onLayout = { [weak self] in self?.publishIfChanged() }
      let interaction = UIHingeInteraction { [weak self] _, update in
        guard let self else { return }
        if let hinge = update.hinge {
          self.hinge = [
            "status": Self.name(of: hinge.status),
            "angle": Double(hinge.angle),
          ]
        } else {
          self.hinge = nil
        }
        self.publishIfChanged()
      }
      probe.addInteraction(interaction)
      view.addSubview(probe)
    #endif
  }

  private func publishIfChanged() {
    let state = state() as NSDictionary
    guard state != lastState else { return }
    lastState = state
    channel.invokeMethod("stateChanged", arguments: state)
  }

  /// Region frames are in the Flutter view's points, which are Flutter's
  /// logical pixels. Inactive regions are included (flagged): iOS marks the
  /// fold inactive while the device is flat, and Dart still reports it as a
  /// flat fold.
  private func state() -> [String: Any] {
    var regions: [[String: Any]] = []
    #if compiler(>=6.4)
      if #available(iOS 27.1, *), let view = hostView {
        for (kind, name) in [
          (UIView.ReservedRegion.Kind.division, "division"),
          (UIView.ReservedRegion.Kind.occlusion, "occlusion"),
        ] {
          for region in view.reservedRegions(kind: kind, options: .includeInactive) {
            regions.append([
              "kind": name,
              "active": region.isActive,
              "left": Double(region.frame.minX),
              "top": Double(region.frame.minY),
              "width": Double(region.frame.width),
              "height": Double(region.frame.height),
              "margins": [
                Double(region.margins.left),
                Double(region.margins.top),
                Double(region.margins.right),
                Double(region.margins.bottom),
              ],
            ])
          }
        }
      }
    #endif
    var state: [String: Any] = ["regions": regions]
    if let hinge { state["hinge"] = hinge }
    return state
  }

  #if compiler(>=6.4)
    @available(iOS 27.1, *)
    private static func name(of status: UIHinge.Status) -> String {
      switch status {
      case .closed: return "closed"
      case .partiallyOpen: return "partiallyOpen"
      case .fullyOpen: return "fullyOpen"
      default: return "unknown"
      }
    }
  #endif
}

/// Follows the Flutter view's bounds and reports every layout pass. It draws
/// nothing and never takes touches or accessibility focus.
private final class FoldProbeView: UIView {
  var onLayout: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    autoresizingMask = [.flexibleWidth, .flexibleHeight]
    isUserInteractionEnabled = false
    isAccessibilityElement = false
    accessibilityElementsHidden = true
    backgroundColor = .clear
  }

  required init?(coder: NSCoder) { nil }

  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?()
  }

  override func safeAreaInsetsDidChange() {
    super.safeAreaInsetsDidChange()
    onLayout?()
  }
}
