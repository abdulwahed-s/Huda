import Flutter
import UIKit
import UserNotifications
import alarm
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var miqaatLockHandler: MiqaatLockMethodHandler?
  private var prayerPushChannel: FlutterMethodChannel?
  private var apnsDeviceToken: String?

  private var apnsEnvironment: String {
#if DEBUG
    return "development"
#else
    return "production"
#endif
  }
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    if #available(iOS 13.0, *) {
      WorkmanagerPlugin.registerPeriodicTask(
        withIdentifier: "com.aw.huda.prayerNotifications.refresh",
        frequency: NSNumber(value: 12 * 60 * 60)
      )
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      miqaatLockHandler = MiqaatLockMethodHandler(messenger: controller.binaryMessenger)
      let channel = FlutterMethodChannel(
        name: "com.aw.huda/prayer_push",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "register" else {
          result(FlutterMethodNotImplemented)
          return
        }
        DispatchQueue.main.async {
          application.registerForRemoteNotifications()
        }
        result(self?.registrationPayload() ?? ["environment": "development"])
      }
      prayerPushChannel = channel
    }
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    SwiftAlarmPlugin.registerBackgroundTasks()
    
    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    application.registerForRemoteNotifications()
    return launched
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    apnsDeviceToken = deviceToken.map { String(format: "%02x", $0) }.joined()
    prayerPushChannel?.invokeMethod("tokenUpdated", arguments: registrationPayload())
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    prayerPushChannel?.invokeMethod(
      "registrationFailed",
      arguments: error.localizedDescription
    )
    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if notification.request.content.userInfo["type"] as? String == "prayer_time" {
      completionHandler([.banner, .list, .sound, .badge])
      return
    }
    super.userNotificationCenter(
      center,
      willPresent: notification,
      withCompletionHandler: completionHandler
    )
  }

  private func registrationPayload() -> [String: String] {
    var payload = ["environment": apnsEnvironment]
    if let token = apnsDeviceToken {
      payload["token"] = token
    }
    return payload
  }
}
