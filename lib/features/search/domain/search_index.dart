import '../../../core/util/text_search.dart';
import '../../announcements/domain/announcement.dart';
import '../../businesses/domain/business.dart';
import '../../contacts/domain/contacts.dart';
import '../../events/events.dart';
import '../../explore/domain/explore.dart';
import '../../pharmacy/domain/pharmacy.dart';
import '../../transport/domain/transport.dart';

/// Aramada "Sayfalar" bölümünde çıkan kısayollar. Ek anahtar kelimeler
/// Türkçe yazılır; arama harf farklarını (ı/i, ş/s, â/a…) yok sayar.
enum SearchPage {
  emergency(['acil', '112', 'deprem', 'afet', 'toplanma', 'ambulans', 'itfaiye', 'polis', 'jandarma', 'yardım', 'sos', 'zehir']),
  pharmacy(['eczane', 'nöbetçi', 'ilaç']),
  prayer(['namaz', 'ezan', 'vakit', 'imsakiye', 'imsak', 'öğle', 'ikindi', 'akşam', 'yatsı']),
  ferry(['feribot', 'vapur', 'deniz otobüsü', 'avşa', 'marmara adası', 'paşalimanı', 'ekinlik']),
  bus(['otobüs', 'minibüs', 'dolmuş', 'bandırma', 'balıkesir', 'bursa', 'istanbul']),
  weather(['hava', 'sıcaklık', 'yağmur', 'kar', 'tahmin', 'güneş', 'derece']),
  wind(['rüzgar', 'poyraz', 'lodos', 'fırtına', 'bofor', 'beaufort', 'esinti']),
  sea(['deniz', 'su sıcaklığı', 'dalga', 'yüzme', 'denize girilir']),
  map(['harita', 'konum']),
  nearby(['yakın', 'yakınımda', 'en yakın', 'çevre', 'atm', 'bankamatik', 'taksi', 'otopark', 'tuvalet', 'wc', 'şarj', 'benzin', 'akaryakıt']),
  favorites(['favori', 'yıldız', 'kaydettiklerim']),
  outages(['kesinti', 'su kesintisi', 'elektrik kesintisi', 'elektrik', 'su', 'doğalgaz', 'arıza', 'baski', 'uedaş']),
  markets(['pazar', 'semt pazarı', 'pazar yeri', 'halk pazarı', 'sebze', 'meyve']),
  events(['etkinlik', 'konser', 'festival', 'şenlik', 'tiyatro', 'sergi', 'fuar']),
  ramadan(['ramazan', 'iftar', 'sahur', 'oruç', 'kadir', 'bayram']),
  businesses(['işletme', 'restoran', 'lokanta', 'kafe', 'otel', 'pansiyon', 'market', 'alışveriş', 'esnaf']),
  trips(['rota', 'gezi rotası', 'yürüyüş', 'trekking', 'bisiklet', 'tekne turu', 'ada turu', 'kapıdağ', 'patika']),
  beaches(['plaj', 'kumsal', 'mavi bayrak', 'denize girilir', 'yüzme', 'deniz']),
  places(['gezi', 'gezilecek', 'plaj', 'koy', 'müze', 'manzara']),
  ataturk(['atatürk', 'savarona', '24 haziran', 'kurtuluş', '18 eylül', 'anıt']),
  erdekspor(['erdekspor', 'futbol', 'maç', 'fikstür', 'puan durumu', 'spor', 'lig']),
  history(['tarih', 'kyzikos', 'antik', 'artake']),
  settings(['ayar', 'bildirim', 'tema', 'karanlık', 'gizlilik', 'dil']);

  const SearchPage(this.keywords);

  final List<String> keywords;
}

/// Arama sonuçları (bölüm bölüm). Her liste en fazla [limit] öğe.
class SearchResults {
  const SearchResults({
    this.pages = const [],
    this.helpLines = const [],
    this.pharmacies = const [],
    this.businesses = const [],
    this.events = const [],
    this.contacts = const [],
    this.routes = const [],
    this.announcements = const [],
    this.places = const [],
  });

  final List<SearchPage> pages;

  /// 112 ve ulusal hatlar (uygulamaya gömülü).
  final List<Contact> helpLines;
  final List<Pharmacy> pharmacies;
  final List<Business> businesses;
  final List<CityEvent> events;
  final List<Contact> contacts;
  final List<TransportRoute> routes;
  final List<Announcement> announcements;
  final List<Place> places;

  bool get isEmpty =>
      pages.isEmpty &&
      helpLines.isEmpty &&
      pharmacies.isEmpty &&
      businesses.isEmpty &&
      events.isEmpty &&
      contacts.isEmpty &&
      routes.isEmpty &&
      announcements.isEmpty &&
      places.isEmpty;

  int get total =>
      pages.length +
      helpLines.length +
      pharmacies.length +
      businesses.length +
      events.length +
      contacts.length +
      routes.length +
      announcements.length +
      places.length;
}

/// Yüklenmiş verilerde arama (cihazda, internetsiz).
/// [pageTitles]: her sayfanın ekrandaki adı (dil dosyasından).
SearchResults searchAll({
  required String query,
  required DateTime now,
  Map<SearchPage, String> pageTitles = const {},
  List<Contact> helpLines = const [],
  PharmacyData? pharmacy,
  BusinessesData? businesses,
  List<CityEvent> events = const [],
  ContactsData? contacts,
  TransportData? transport,
  AnnouncementsData? announcements,
  PlacesData? places,
  int limit = 8,
}) {
  if (query.trim().length < 2) return const SearchResults();
  bool m(Iterable<String?> fields) => TextSearch.matches(query, fields);

  return SearchResults(
    pages: [
      for (final page in SearchPage.values)
        if (pageTitles[page] case final title?)
          if (m([title, ...page.keywords])) page,
    ].take(4).toList(),
    helpLines: [
      ...helpLines.where((c) => m([c.name, c.phone, c.note])),
    ].take(limit).toList(),
    pharmacies: [
      ...?pharmacy?.pharmacies.where((p) => m([p.name, p.address])),
    ].take(limit).toList(),
    businesses: [
      for (final b in businesses?.businesses ?? const <Business>[])
        if (m([b.name, businesses!.categoryOf(b)?.title, b.summary, b.description, b.address])) b,
    ].take(limit).toList(),
    events: [
      ...events.where((e) => m([e.title, e.place, e.summary, e.organizer])),
    ].take(limit).toList(),
    contacts: [
      for (final c in contacts?.categories ?? const <ContactCategory>[])
        for (final contact in c.contacts)
          if (m([contact.name, contact.note, c.title])) contact,
    ].take(limit).toList(),
    routes: [
      ...?transport?.routes.where((r) => m([r.title, r.from, r.to, r.operatorName])),
    ].take(limit).toList(),
    announcements: [
      ...?announcements?.activeAt(now).where((a) => m([a.title, a.body])),
    ].take(limit).toList(),
    places: [
      ...?places?.places.where((p) => m([p.title, p.summary])),
    ].take(limit).toList(),
  );
}

/// Son aramalar listesine [query] ekler: başa alır, tekrarı siler, en fazla [max].
List<String> pushRecent(List<String> recent, String query, {int max = 8}) {
  final q = query.trim();
  if (q.length < 2) return recent;
  final key = TextSearch.normalize(q);
  return [q, ...recent.where((r) => TextSearch.normalize(r) != key)].take(max).toList();
}
