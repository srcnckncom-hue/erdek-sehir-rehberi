import CoreLocation
import EventKit
import EventKitUI
import Flutter
import MapKit
import StoreKit
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Ana ekran widget'ı ile paylaşılan alan (ios/ErdekWidget).
  private static let appGroup = "group.com.erdek.sehirrehberi.erdekrehberi"

  /// "Yakınımdakiler" için konum (lib/features/nearby/location_service.dart).
  private let locationProvider = LocationProvider()

  /// Etkinliği takvime ekleme penceresi (lib/features/events).
  fileprivate static let calendar = CalendarPresenter()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications: uygulama açıkken de vakit bildirimleri
    // görünsün diye bildirim merkezinin temsilcisi uygulama olur.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    // firebase_messaging (UIScene yaşam döngüsü): bildirim merkezi temsilcisi
    // didFinishLaunching bitmeden kurulmalı. Eklenti başlığını içe aktarmadan,
    // çalışma anında çağrılır (eklenti yoksa sessizce geçer). Önceki temsilci
    // (yerel vakit bildirimleri) eklenti tarafından korunur ve ona iletilir.
    if let pluginClass = NSClassFromString("FLTFirebaseMessagingPlugin") {
      let target = pluginClass as AnyObject
      let selector = NSSelectorFromString("configureNotificationCenterDelegate")
      if target.responds(to: selector) {
        _ = target.perform(selector)
      }
    }
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
        case "addToCalendar":
          let args = call.arguments as? [String: Any] ?? [:]
          AppDelegate.calendar.present(args, from: AppDelegate.topViewController, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    // Flutter → konum (yalnızca istenince; telefonda kalır).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ErdekLocationChannel") {
      let channel = FlutterMethodChannel(name: "erdek/location", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "current", let self else {
          result(FlutterMethodNotImplemented)
          return
        }
        self.locationProvider.request(result)
      }
    }

    // Erdek haritası (Apple Haritalar; lib/features/map/map_screen.dart).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ErdekMapView") {
      registrar.register(ErdekMapFactory(messenger: registrar.messenger()), withId: "erdek/map")
    }
  }

  private static func activeScene() -> UIWindowScene? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
      ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
  }

  /// En üstte görünen ekran (pencere açmak için).
  fileprivate static func topViewController() -> UIViewController? {
    guard let scene = activeScene(),
          let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? scene.windows.first?.rootViewController
    else { return nil }
    var top = root
    while let presented = top.presentedViewController { top = presented }
    return top
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

// MARK: - Konum

/// Tek seferlik konum isteği. İzin yoksa önce iOS izin penceresi.
final class LocationProvider: NSObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var pending: [FlutterResult] = []

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
  }

  func request(_ result: @escaping FlutterResult) {
    pending.append(result)
    switch manager.authorizationStatus {
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .denied, .restricted:
      finish(error: "denied")
    default:
      manager.requestLocation()
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard !pending.isEmpty else { return }
    switch manager.authorizationStatus {
    case .notDetermined:
      return
    case .denied, .restricted:
      finish(error: "denied")
    default:
      manager.requestLocation()
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let last = locations.last else { return }
    let value: [String: Double] = [
      "lat": last.coordinate.latitude,
      "lng": last.coordinate.longitude,
      "accuracy": last.horizontalAccuracy,
    ]
    let callbacks = pending
    pending.removeAll()
    callbacks.forEach { $0(value) }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    finish(error: "unavailable")
  }

  private func finish(error code: String) {
    let callbacks = pending
    pending.removeAll()
    callbacks.forEach { $0(FlutterError(code: code, message: nil, details: nil)) }
  }
}

// MARK: - Harita (MapKit)

final class ErdekMapFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    ErdekMapView(frame: frame, viewId: viewId, args: args, messenger: messenger)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

final class ErdekPin: NSObject, MKAnnotation {
  let id: String
  let kind: String
  let coordinate: CLLocationCoordinate2D
  let title: String?
  let subtitle: String?

  init(id: String, kind: String, coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
    self.id = id
    self.kind = kind
    self.coordinate = coordinate
    self.title = title
    self.subtitle = subtitle
  }
}

/// Flutter'dan gelen iğneleri gösterir; balondaki (i) düğmesine dokununca
/// "select" ile kimliği Flutter'a bildirir.
final class ErdekMapView: NSObject, FlutterPlatformView, MKMapViewDelegate {
  private let map: MKMapView
  private let channel: FlutterMethodChannel

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    map = MKMapView(frame: frame)
    channel = FlutterMethodChannel(name: "erdek/map_\(viewId)", binaryMessenger: messenger)
    super.init()
    map.delegate = self
    map.pointOfInterestFilter = .excludingAll
    let params = args as? [String: Any]
    let lat = params?["centerLat"] as? Double ?? 40.3955
    let lng = params?["centerLng"] as? Double ?? 27.7930
    map.setRegion(
      MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
        span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
      ),
      animated: false
    )
    let status = CLLocationManager().authorizationStatus
    map.showsUserLocation = status == .authorizedWhenInUse || status == .authorizedAlways
    setPins(params?["pins"] as? [[String: Any]] ?? [])
    // Gezi rotası: çizgi (enlem, boylam çiftleri) + tümünü sığdır.
    if let path = params?["path"] as? [[Double]] {
      let coords = path.compactMap { $0.count == 2 ? CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) : nil }
      if coords.count > 1 { map.addOverlay(MKPolyline(coordinates: coords, count: coords.count)) }
    }
    if params?["fit"] as? Bool == true { fitAll() }
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      if call.method == "setPins" {
        self.setPins(call.arguments as? [[String: Any]] ?? [])
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func view() -> UIView { map }

  /// İğneler ve rota çizgisi ekrana sığsın.
  private func fitAll() {
    var rect = MKMapRect.null
    for annotation in map.annotations where annotation is ErdekPin {
      let point = MKMapPoint(annotation.coordinate)
      rect = rect.union(MKMapRect(x: point.x, y: point.y, width: 1, height: 1))
    }
    for overlay in map.overlays { rect = rect.union(overlay.boundingMapRect) }
    guard !rect.isNull else { return }
    map.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 48, left: 48, bottom: 48, right: 48), animated: false)
  }

  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    guard let line = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
    let renderer = MKPolylineRenderer(polyline: line)
    renderer.strokeColor = UIColor(red: 0.15, green: 0.56, blue: 0.77, alpha: 0.9)
    renderer.lineWidth = 4
    return renderer
  }

  private func setPins(_ items: [[String: Any]]) {
    map.removeAnnotations(map.annotations.filter { $0 is ErdekPin })
    let pins: [ErdekPin] = items.compactMap { item in
      guard let id = item["id"] as? String,
            let lat = item["lat"] as? Double,
            let lng = item["lng"] as? Double
      else { return nil }
      return ErdekPin(
        id: id,
        kind: item["kind"] as? String ?? "place",
        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
        title: item["title"] as? String,
        subtitle: item["subtitle"] as? String
      )
    }
    map.addAnnotations(pins)
  }

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard let pin = annotation as? ErdekPin else { return nil }
    let reuse = "erdek-pin"
    let view = (mapView.dequeueReusableAnnotationView(withIdentifier: reuse) as? MKMarkerAnnotationView)
      ?? MKMarkerAnnotationView(annotation: pin, reuseIdentifier: reuse)
    view.annotation = pin
    view.canShowCallout = true
    view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
    view.glyphText = nil
    switch pin.kind {
    case "stop":
      // Rota durağı: numaralı yeşil iğne ("stop:3" → 3), balonda düğme yok.
      view.markerTintColor = UIColor(red: 0.13, green: 0.55, blue: 0.35, alpha: 1)
      view.glyphImage = nil
      view.glyphText = pin.id.split(separator: ":").last.map(String.init)
      view.rightCalloutAccessoryView = nil
      view.displayPriority = .required
    case "pharmacy":
      view.markerTintColor = UIColor(red: 0.78, green: 0.11, blue: 0.09, alpha: 1)
      view.glyphImage = UIImage(systemName: "cross.case.fill")
      view.displayPriority = .required
    case "business":
      view.markerTintColor = UIColor(red: 0.93, green: 0.41, blue: 0.11, alpha: 1)
      view.glyphImage = UIImage(systemName: "storefront.fill")
      view.displayPriority = .defaultHigh
    // Hizmet noktaları (taksi, ATM, otopark, WC, şarj, akaryakıt): sıkışınca önce bunlar gizlenir.
    case "taxi", "atm", "parking", "wc", "charging", "fuel":
      let style: [String: (UIColor, String)] = [
        "taxi": (UIColor(red: 0.96, green: 0.70, blue: 0.0, alpha: 1), "car.fill"),
        "atm": (UIColor(red: 0.13, green: 0.55, blue: 0.35, alpha: 1), "banknote.fill"),
        "parking": (UIColor(red: 0.16, green: 0.38, blue: 0.85, alpha: 1), "parkingsign"),
        "wc": (UIColor(red: 0.10, green: 0.60, blue: 0.65, alpha: 1), "toilet.fill"),
        "charging": (UIColor(red: 0.45, green: 0.30, blue: 0.80, alpha: 1), "bolt.car.fill"),
        "fuel": (UIColor(red: 0.80, green: 0.20, blue: 0.25, alpha: 1), "fuelpump.fill"),
      ]
      let (color, symbol) = style[pin.kind]!
      view.markerTintColor = color
      view.glyphImage = UIImage(systemName: symbol) ?? UIImage(systemName: "mappin")
      view.displayPriority = .defaultLow
    default:
      view.markerTintColor = UIColor(red: 0.15, green: 0.56, blue: 0.77, alpha: 1)
      view.glyphImage = UIImage(systemName: "mappin.and.ellipse")
      view.displayPriority = .defaultHigh
    }
    return view
  }

  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    guard let pin = view.annotation as? ErdekPin else { return }
    channel.invokeMethod("select", arguments: pin.id)
  }
}

// MARK: - Takvim

/// Etkinliği iOS'un kendi "Etkinlik ekle" penceresiyle takvime ekler; kullanıcı
/// pencerede düzenleyip "Ekle"ye basar. iOS 17+: izin istenmez (pencere
/// uygulamanın dışında çalışır). Daha eski iOS: bir kez takvim izni sorulur.
final class CalendarPresenter: NSObject, EKEventEditViewDelegate {
  private let store = EKEventStore()
  private var pending: FlutterResult?

  func present(_ args: [String: Any], from top: @escaping () -> UIViewController?, result: @escaping FlutterResult) {
    let show: () -> Void = { [weak self] in
      DispatchQueue.main.async {
        guard let self, let controller = top() else {
          result("unavailable")
          return
        }
        let tz = TimeZone(identifier: "Europe/Istanbul") ?? .current
        let event = EKEvent(eventStore: self.store)
        event.title = args["title"] as? String ?? ""
        event.location = args["location"] as? String
        event.notes = args["notes"] as? String
        if let link = args["url"] as? String { event.url = URL(string: link) }
        event.timeZone = tz
        event.isAllDay = args["allDay"] as? Bool ?? false
        let start = CalendarPresenter.date(args["start"], tz) ?? Date()
        event.startDate = start
        event.endDate = CalendarPresenter.date(args["end"], tz) ?? start.addingTimeInterval(2 * 3600)

        let editor = EKEventEditViewController()
        editor.eventStore = self.store
        editor.event = event
        editor.editViewDelegate = self
        self.pending?("canceled")
        self.pending = result
        controller.present(editor, animated: true)
      }
    }
    if #available(iOS 17.0, *) {
      show()
    } else {
      store.requestAccess(to: .event) { granted, _ in
        if granted {
          show()
        } else {
          DispatchQueue.main.async { result("denied") }
        }
      }
    }
  }

  /// [yıl, ay, gün, saat, dakika] → Date (Erdek saati).
  private static func date(_ value: Any?, _ tz: TimeZone) -> Date? {
    guard let parts = value as? [Int], parts.count == 5 else { return nil }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = tz
    return calendar.date(from: DateComponents(
      year: parts[0], month: parts[1], day: parts[2], hour: parts[3], minute: parts[4]
    ))
  }

  func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
    controller.dismiss(animated: true)
    pending?(action == .saved ? "saved" : "canceled")
    pending = nil
  }
}
