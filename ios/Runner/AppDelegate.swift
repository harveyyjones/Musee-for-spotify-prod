import UIKit
import Flutter
import workmanager
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "updateActiveStatus", frequency: NSNumber(value: 15 * 60))
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
