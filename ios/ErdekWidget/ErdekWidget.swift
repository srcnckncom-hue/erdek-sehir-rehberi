import SwiftUI
import WidgetKit

// Erdek Şehir Rehberi — ana ekran ve kilit ekranı widget'ları.
//  * Erdek Rehberi: sıradaki namaz vakti (orta boyda + nöbetçi eczane)
//  * Nöbetçi Eczane: bugünün nöbetçisi (08:30'da değişir)
//  * Sıradaki Sefer: Erdek'ten kalkan ilk feribot (yoksa otobüs)
// Her biri kilit ekranına da eklenebilir (dikdörtgen, satır; vakitte yuvarlak).
// Veri uygulamadan App Group ile gelir (lib/features/home_widget_sync).

private let appGroup = "group.com.erdek.sehirrehberi.erdekrehberi"
private let dataKey = "widget_data"
private let brandBlue = Color(red: 0x26 / 255, green: 0x8E / 255, blue: 0xC5 / 255)
private let pharmacyRed = Color(red: 0xC8 / 255, green: 0x1C / 255, blue: 0x18 / 255)
private let ferryTeal = Color(red: 0x0E / 255, green: 0x8A / 255, blue: 0x8A / 255)

// MARK: - Veri

struct WidgetPayload: Decodable {
  struct Prayer: Decodable {
    let name: String
    let at: String
  }

  struct Duty: Decodable {
    let from: String
    let to: String
    let names: [String]
  }

  struct Trip: Decodable {
    let mode: String
    let route: String
    let at: String
  }

  let prayers: [Prayer]
  let duties: [Duty]
  let pharmacyIsSample: Bool?
  let departures: [Trip]?

  static func load() -> WidgetPayload? {
    guard let json = UserDefaults(suiteName: appGroup)?.string(forKey: dataKey),
          let data = json.data(using: .utf8)
    else { return nil }
    return try? JSONDecoder().decode(WidgetPayload.self, from: data)
  }
}

private let isoParser: ISO8601DateFormatter = {
  let f = ISO8601DateFormatter()
  f.formatOptions = [.withInternetDateTime]
  return f
}()

private let timeFormatter: DateFormatter = {
  let f = DateFormatter()
  f.locale = Locale(identifier: "tr_TR")
  f.timeZone = TimeZone(identifier: "Europe/Istanbul")
  f.dateFormat = "HH:mm"
  return f
}()

private func hhmm(_ date: Date) -> String { timeFormatter.string(from: date) }

struct NextPrayer {
  let name: String
  let at: Date
}

struct NextTrip {
  let mode: String
  let route: String
  let at: Date
}

struct ErdekEntry: TimelineEntry {
  let date: Date
  let prayer: NextPrayer?
  let pharmacies: [String]
  let pharmacyIsSample: Bool
  let trip: NextTrip?
  let hasData: Bool
}

private struct Parsed {
  let payload: WidgetPayload?
  let prayers: [NextPrayer]
  let trips: [NextTrip]

  init(_ payload: WidgetPayload?) {
    self.payload = payload
    prayers = (payload?.prayers ?? []).compactMap { item in
      isoParser.date(from: item.at).map { NextPrayer(name: item.name, at: $0) }
    }.sorted { $0.at < $1.at }
    trips = (payload?.departures ?? []).compactMap { item in
      isoParser.date(from: item.at).map { NextTrip(mode: item.mode, route: item.route, at: $0) }
    }.sorted { $0.at < $1.at }
  }

  func entry(at date: Date) -> ErdekEntry {
    guard let payload else {
      return ErdekEntry(date: date, prayer: nil, pharmacies: [], pharmacyIsSample: false, trip: nil, hasData: false)
    }
    let duty = payload.duties.first { d in
      guard let from = isoParser.date(from: d.from), let to = isoParser.date(from: d.to) else { return false }
      return from <= date && date < to
    }
    // Önce feribot; bugün/yarın feribot yoksa ilk otobüs.
    let upcoming = trips.filter { $0.at > date }
    let trip = upcoming.first { $0.mode == "ferry" } ?? upcoming.first
    return ErdekEntry(
      date: date,
      prayer: prayers.first { $0.at > date },
      pharmacies: duty?.names ?? [],
      pharmacyIsSample: payload.pharmacyIsSample ?? false,
      trip: trip,
      hasData: true
    )
  }

  /// Giriş değişim anları: vakitler, nöbet değişimi ve sefer kalkışları.
  func changeDates(from now: Date, until horizon: Date) -> [Date] {
    var dates: [Date] = [now]
    dates += prayers.map(\.at).filter { $0 > now && $0 <= horizon }
    dates += trips.map(\.at).filter { $0 > now && $0 <= horizon }
    if let payload {
      dates += payload.duties.compactMap { isoParser.date(from: $0.from) }.filter { $0 > now && $0 <= horizon }
    }
    return Array(Set(dates)).sorted()
  }
}

// MARK: - Zaman çizelgesi

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> ErdekEntry {
    ErdekEntry(
      date: Date(),
      prayer: NextPrayer(name: "Akşam", at: Date().addingTimeInterval(3600)),
      pharmacies: ["Eczane"],
      pharmacyIsSample: false,
      trip: NextTrip(mode: "ferry", route: "Erdek → Avşa", at: Date().addingTimeInterval(5400)),
      hasData: true
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (ErdekEntry) -> Void) {
    let parsed = Parsed(WidgetPayload.load())
    completion(parsed.payload == nil && context.isPreview ? placeholder(in: context) : parsed.entry(at: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ErdekEntry>) -> Void) {
    let now = Date()
    let parsed = Parsed(WidgetPayload.load())
    let horizon = now.addingTimeInterval(36 * 3600)
    // Kilit ekranı için en fazla ~80 giriş (WidgetKit sınırına uzak).
    let entries = parsed.changeDates(from: now, until: horizon).prefix(80).map { parsed.entry(at: $0) }
    let refresh = Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? horizon
    completion(Timeline(entries: Array(entries), policy: .after(min(refresh, horizon))))
  }
}

// MARK: - Ana ekran görünümleri

struct PrayerBlock: View {
  let entry: ErdekEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Label("Sıradaki vakit", systemImage: "moon.stars.fill")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(brandBlue)
      if let p = entry.prayer {
        Text(p.name)
          .font(.title2.weight(.bold))
          .minimumScaleFactor(0.7)
          .lineLimit(1)
        Text(hhmm(p.at))
          .font(.title3.weight(.semibold))
          .monospacedDigit()
        Text(p.at, style: .relative)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      } else {
        Text(entry.hasData ? "Vakit bilgisi yok" : "Uygulamayı bir kez açın")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

struct PharmacyBlock: View {
  let entry: ErdekEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Label("Nöbetçi eczane", systemImage: "cross.case.fill")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(pharmacyRed)
      if entry.pharmacies.isEmpty {
        Text(entry.hasData ? "Bilgi yok" : "Uygulamayı bir kez açın")
          .font(.footnote)
          .foregroundStyle(.secondary)
      } else {
        ForEach(entry.pharmacies.prefix(2), id: \.self) { name in
          Text(name)
            .font(.subheadline.weight(.semibold))
            .lineLimit(2)
            .minimumScaleFactor(0.8)
        }
        Text(entry.pharmacyIsSample ? "ÖRNEK VERİ" : "Sabah 08:30'a kadar")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

struct TripBlock: View {
  let entry: ErdekEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Label(
        entry.trip?.mode == "bus" ? "Sıradaki otobüs" : "Sıradaki feribot",
        systemImage: entry.trip?.mode == "bus" ? "bus.fill" : "ferry.fill"
      )
      .font(.caption2.weight(.semibold))
      .foregroundStyle(ferryTeal)
      if let t = entry.trip {
        Text(hhmm(t.at))
          .font(.title2.weight(.bold))
          .monospacedDigit()
        Text(t.route)
          .font(.subheadline.weight(.semibold))
          .lineLimit(2)
          .minimumScaleFactor(0.8)
        Text(t.at, style: .relative)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      } else {
        Text(entry.hasData ? "Bugün ve yarın sefer yok" : "Uygulamayı bir kez açın")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

// MARK: - Kilit ekranı görünümleri

/// Kilit ekranı dikdörtgen: başlık + büyük satır + küçük satır.
struct AccessoryRect: View {
  let icon: String
  let title: String
  let main: String
  let detail: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Label(title, systemImage: icon)
        .font(.caption2.weight(.semibold))
        .lineLimit(1)
      Text(main)
        .font(.headline)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      if let detail {
        Text(detail)
          .font(.caption2)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - Widget görünümleri

struct PrayerWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: ErdekEntry

  var body: some View {
    Group {
      switch family {
      case .systemMedium:
        HStack(alignment: .top, spacing: 12) {
          PrayerBlock(entry: entry)
          Divider()
          PharmacyBlock(entry: entry)
        }
      case .accessoryRectangular:
        if let p = entry.prayer {
          AccessoryRect(icon: "moon.stars.fill", title: "Sıradaki vakit", main: "\(p.name) \(hhmm(p.at))", detail: nil)
        } else {
          AccessoryRect(icon: "moon.stars.fill", title: "Erdek Rehberi", main: "Vakit yok", detail: nil)
        }
      case .accessoryCircular:
        ZStack {
          AccessoryWidgetBackground()
          VStack(spacing: 0) {
            Image(systemName: "moon.stars.fill").font(.caption2)
            Text(entry.prayer.map { hhmm($0.at) } ?? "--:--")
              .font(.system(size: 13, weight: .semibold))
              .monospacedDigit()
              .minimumScaleFactor(0.6)
          }
        }
      case .accessoryInline:
        if let p = entry.prayer {
          Label("\(p.name) \(hhmm(p.at))", systemImage: "moon.stars.fill")
        } else {
          Text("Erdek Rehberi")
        }
      default:
        PrayerBlock(entry: entry)
      }
    }
    .widgetBackground(family)
  }
}

struct PharmacyWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: ErdekEntry

  var body: some View {
    Group {
      switch family {
      case .accessoryRectangular:
        AccessoryRect(
          icon: "cross.case.fill",
          title: "Nöbetçi eczane",
          main: entry.pharmacies.first ?? "Bilgi yok",
          detail: entry.pharmacies.count > 1 ? entry.pharmacies[1] : "08:30'a kadar"
        )
      case .accessoryInline:
        Label(entry.pharmacies.first ?? "Nöbetçi eczane", systemImage: "cross.case.fill")
      default:
        PharmacyBlock(entry: entry)
      }
    }
    .widgetBackground(family)
  }
}

struct TripWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: ErdekEntry

  var body: some View {
    Group {
      switch family {
      case .accessoryRectangular:
        if let t = entry.trip {
          AccessoryRect(
            icon: t.mode == "bus" ? "bus.fill" : "ferry.fill",
            title: t.route,
            main: hhmm(t.at),
            detail: nil
          )
        } else {
          AccessoryRect(icon: "ferry.fill", title: "Sıradaki sefer", main: "Sefer yok", detail: nil)
        }
      case .accessoryInline:
        if let t = entry.trip {
          Label("\(hhmm(t.at)) \(t.route)", systemImage: t.mode == "bus" ? "bus.fill" : "ferry.fill")
        } else {
          Text("Sefer yok")
        }
      default:
        TripBlock(entry: entry)
      }
    }
    .widgetBackground(family)
  }
}

private extension View {
  @ViewBuilder
  func widgetBackground(_ family: WidgetFamily) -> some View {
    let isAccessory = family == .accessoryRectangular || family == .accessoryCircular || family == .accessoryInline
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) {
        if isAccessory { Color.clear } else { Color(.systemBackground) }
      }
    } else if isAccessory {
      self
    } else {
      padding().background(Color(.systemBackground))
    }
  }
}

// MARK: - Widget'lar

struct ErdekWidget: Widget {
  let kind = "ErdekWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      PrayerWidgetView(entry: entry)
    }
    .configurationDisplayName("Erdek Rehberi")
    .description("Sıradaki namaz vakti ve nöbetçi eczane.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
  }
}

struct ErdekPharmacyWidget: Widget {
  let kind = "ErdekPharmacyWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      PharmacyWidgetView(entry: entry)
    }
    .configurationDisplayName("Nöbetçi Eczane")
    .description("Erdek'te bugünün nöbetçi eczanesi (08:30'da değişir).")
    .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
  }
}

struct ErdekTripWidget: Widget {
  let kind = "ErdekTripWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      TripWidgetView(entry: entry)
    }
    .configurationDisplayName("Sıradaki Sefer")
    .description("Erdek'ten kalkan sıradaki feribot (yoksa otobüs).")
    .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
  }
}

@main
struct ErdekWidgets: WidgetBundle {
  var body: some Widget {
    ErdekWidget()
    ErdekPharmacyWidget()
    ErdekTripWidget()
  }
}
