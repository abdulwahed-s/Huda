import Flutter
import UIKit
import UserNotifications
import alarm

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var miqaatLockHandler: MiqaatLockMethodHandler?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      miqaatLockHandler = MiqaatLockMethodHandler(messenger: controller.binaryMessenger)
    }
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    SwiftAlarmPlugin.registerBackgroundTasks()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
