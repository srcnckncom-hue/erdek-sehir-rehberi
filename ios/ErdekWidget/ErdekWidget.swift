import SwiftUI
import WidgetKit

// Erdek Şehir Rehberi — ana ekran widget'ı.
// Küçük: sıradaki namaz vakti. Orta: + bugünün nöbetçi eczanesi.
// Veri uygulamadan App Group ile gelir (lib/features/home_widget_sync).

private let appGroup = "group.com.erdek.sehirrehberi.erdekrehberi"
private let dataKey = "widget_data"
private let brandBlue = Color(red: 0, green: 0x57 / 255, blue: 0xFC / 255)
private let pharmacyRed = Color(red: 0xC8 / 255, green: 0x1C / 255, blue: 0x18 / 255)

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

  let prayers: [Prayer]
  let duties: [Duty]
  let pharmacyIsSample: Bool?

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

struct NextPrayer {
  let name: String
  let at: Date
}

struct ErdekEntry: TimelineEntry {
  let date: Date
  let prayer: NextPrayer?
  let pharmacies: [String]
  let pharmacyIsSample: Bool
  let hasData: Bool
}

private func parsePrayers(_ p: WidgetPayload) -> [NextPrayer] {
  p.prayers.compactMap { item in
    isoParser.date(from: item.at).map { NextPrayer(name: item.name, at: $0) }
  }.sorted { $0.at < $1.at }
}

private func entry(at date: Date, payload: WidgetPayload?, prayers: [NextPrayer]) -> ErdekEntry {
  guard let payload else {
    return ErdekEntry(date: date, prayer: nil, pharmacies: [], pharmacyIsSample: false, hasData: false)
  }
  let next = prayers.first { $0.at > date }
  let duty = payload.duties.first { d in
    guard let from = isoParser.date(from: d.from), let to = isoParser.date(from: d.to) else { return false }
    return from <= date && date < to
  }
  return ErdekEntry(
    date: date,
    prayer: next,
    pharmacies: duty?.names ?? [],
    pharmacyIsSample: payload.pharmacyIsSample ?? false,
    hasData: true
  )
}

// MARK: - Zaman çizelgesi

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> ErdekEntry {
    ErdekEntry(
      date: Date(),
      prayer: NextPrayer(name: "Akşam", at: Date().addingTimeInterval(3600)),
      pharmacies: ["Eczane"],
      pharmacyIsSample: false,
      hasData: true
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (ErdekEntry) -> Void) {
    let payload = WidgetPayload.load()
    let prayers = payload.map(parsePrayers) ?? []
    completion(payload == nil && context.isPreview ? placeholder(in: context) : entry(at: Date(), payload: payload, prayers: prayers))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ErdekEntry>) -> Void) {
    let now = Date()
    let payload = WidgetPayload.load()
    let prayers = payload.map(parsePrayers) ?? []
    let horizon = now.addingTimeInterval(36 * 3600)

    // Vakit girişlerinde ve nöbet değişiminde (08:30) yeni giriş.
    var dates: [Date] = [now]
    dates += prayers.map(\.at).filter { $0 > now && $0 <= horizon }
    if let payload {
      dates += payload.duties.compactMap { isoParser.date(from: $0.from) }.filter { $0 > now && $0 <= horizon }
    }
    let entries = Set(dates).sorted().map { entry(at: $0, payload: payload, prayers: prayers) }
    let refresh = Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? horizon
    completion(Timeline(entries: entries, policy: .after(min(refresh, horizon))))
  }
}

// MARK: - Görünüm

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
        Text(timeFormatter.string(from: p.at))
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
        Text(entry.hasData ? "Bilgi yok" : "—")
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

struct ErdekWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: ErdekEntry

  var body: some View {
    Group {
      if family == .systemMedium {
        HStack(alignment: .top, spacing: 12) {
          PrayerBlock(entry: entry)
          Divider()
          PharmacyBlock(entry: entry)
        }
      } else {
        PrayerBlock(entry: entry)
      }
    }
    .widgetBackground()
  }
}

private extension View {
  @ViewBuilder
  func widgetBackground() -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) { Color(.systemBackground) }
    } else {
      padding().background(Color(.systemBackground))
    }
  }
}

// MARK: - Widget

@main
struct ErdekWidget: Widget {
  let kind = "ErdekWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      ErdekWidgetView(entry: entry)
    }
    .configurationDisplayName("Erdek Rehberi")
    .description("Sıradaki namaz vakti ve nöbetçi eczane.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
