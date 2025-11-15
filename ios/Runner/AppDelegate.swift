import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(name: "qmail/oauth", binaryMessenger: controller.binaryMessenger)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if url.scheme == "qmail" {
      methodChannel?.invokeMethod("handleOAuthCallback", arguments: ["url": url.absoluteString])
    }
    return true
  }
}
