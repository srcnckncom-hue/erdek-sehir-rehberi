import Flutter
import StoreKit
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

    // Flutter → iOS yerel özellikleri (lib/core/system/system_bridge.dart):
    // paylaşım penceresi, Apple puanlama penceresi, sürüm numarası.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ErdekSystemChannel") {
      let channel = FlutterMethodChannel(name: "erdek/system", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "share":
          let args = call.arguments as? [String: Any]
          let text = args?["text"] as? String ?? ""
          AppDelegate.presentShareSheet(text: text)
          result(nil)
        case "requestReview":
          if let scene = AppDelegate.activeScene() {
            SKStoreReviewController.requestReview(in: scene)
          }
          result(nil)
        case "appVersion":
          let info = Bundle.main.infoDictionary
          let version = info?["CFBundleShortVersionString"] as? String ?? "?"
          let build = info?["CFBundleVersion"] as? String ?? "?"
          result("\(version) (\(build))")
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }

  private static func activeScene() -> UIWindowScene? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
      ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
  }

  private static func presentShareSheet(text: String) {
    guard let scene = activeScene(),
          let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? scene.windows.first?.rootViewController
    else { return }
    var top = root
    while let presented = top.presentedViewController { top = presented }
    let sheet = UIActivityViewController(activityItems: [text], applicationActivities: nil)
    // iPad: açılır pencere ekranın ortasından çıksın.
    if let popover = sheet.popoverPresentationController {
      popover.sourceView = top.view
      popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }
    top.present(sheet, animated: true)
  }
}
