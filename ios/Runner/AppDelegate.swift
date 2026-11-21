import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Ana ekran widget'ı ile paylaşılan alan (ios/ErdekWidget).
  private static let appGroup = "group.com.erdek.sehirrehberi.erdekrehberi"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications: uygulama açıkken de vakit bildirimleri
    // görünsün diye bildirim merkezinin temsilcisi uygulama olur.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Flutter → widget verisi (lib/features/home_widget_sync/widget_sync.dart)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ErdekWidgetChannel") {
      let channel = FlutterMethodChannel(name: "erdek/widget", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "update", let json = call.arguments as? String else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let defaults = UserDefaults(suiteName: AppDelegate.appGroup) else {
          result(FlutterError(code: "no_app_group", message: "App Group erişilemedi", details: nil))
          return
        }
        defaults.set(json, forKey: "widget_data")
        WidgetCenter.shared.reloadAllTimelines()
        result(nil)
      }
    }
  }
}
