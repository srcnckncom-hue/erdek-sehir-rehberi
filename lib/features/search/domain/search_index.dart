import '../../../core/util/text_search.dart';
import '../../announcements/domain/announcement.dart';
import '../../contacts/domain/contacts.dart';
import '../../pharmacy/domain/pharmacy.dart';
import '../../transport/domain/transport.dart';

/// Arama sonuçları (bölüm bölüm). Her liste en fazla [limit] öğe.
class SearchResults {
  const SearchResults({
    this.pharmacies = const [],
    this.contacts = const [],
    this.routes = const [],
    this.announcements = const [],
  });

  final List<Pharmacy> pharmacies;
  final List<Contact> contacts;
  final List<TransportRoute> routes;
  final List<Announcement> announcements;

  bool get isEmpty =>
      pharmacies.isEmpty && contacts.isEmpty && routes.isEmpty && announcements.isEmpty;
}

/// Yüklenmiş verilerde arama (cihazda, internetsiz).
SearchResults searchAll({
  required String query,
  required DateTime now,
  PharmacyData? pharmacy,
  ContactsData? contacts,
  TransportData? transport,
  AnnouncementsData? announcements,
  int limit = 8,
}) {
  if (query.trim().length < 2) return const SearchResults();
  bool m(Iterable<String?> fields) => TextSearch.matches(query, fields);

  return SearchResults(
    pharmacies: [
      ...?pharmacy?.pharmacies.where((p) => m([p.name, p.address])),
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
  );
}
