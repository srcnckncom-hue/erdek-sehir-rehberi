import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../businesses/data/businesses_repository.dart';
import '../businesses/domain/business.dart';
import '../explore/data/explore_repository.dart';
import '../explore/domain/explore.dart';
import '../pharmacy/data/pharmacy_repository.dart';
import '../pharmacy/domain/duty_schedule.dart';
import '../pharmacy/domain/pharmacy.dart';
import 'location_service.dart';

enum PointKind { pharmacy, business, place }

/// Haritada / yakınımdakilerde gösterilen bir yer.
class PointOfInterest {
  const PointOfInterest({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle,
    this.location,
    this.pharmacy,
    this.business,
    this.businessCategory,
    this.place,
  });

  /// "pharmacy:ID", "business:ID", "place:ID" (harita seçimi için tekil).
  final String id;
  final PointKind kind;
  final String title;
  final String? subtitle;
  final GeoPoint? location;

  // Ayrıntı sayfası için kaynak kayıt (türüne göre biri dolu).
  final Pharmacy? pharmacy;
  final Business? business;
  final BusinessCategory? businessCategory;
  final Place? place;

  Map<String, Object?> toPin() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'subtitle': subtitle,
        'lat': location?.latitude,
        'lng': location?.longitude,
      };
}

GeoPoint? _point(double? lat, double? lng) => lat == null || lng == null ? null : GeoPoint(lat, lng);

/// Bugünün nöbetçi eczaneleri + işletmeler + gezilecek yerler.
/// [pharmacyLabel]: eczane alt başlığı ("Nöbetçi eczane").
List<PointOfInterest> collectPoints({
  required DateTime erdekNow,
  required String pharmacyLabel,
  PharmacyData? pharmacy,
  BusinessesData? businesses,
  PlacesData? places,
}) {
  final duty = dutyDateFor(erdekNow);
  return [
    for (final p in pharmacy?.onDutyFor(duty) ?? const <Pharmacy>[])
      PointOfInterest(
        id: 'pharmacy:${p.id}',
        kind: PointKind.pharmacy,
        title: p.name,
        subtitle: pharmacyLabel,
        location: _point(p.latitude, p.longitude),
        pharmacy: p,
      ),
    for (final b in businesses?.businesses ?? const <Business>[])
      PointOfInterest(
        id: 'business:${b.id}',
        kind: PointKind.business,
        title: b.name,
        subtitle: businesses!.categoryOf(b)?.title,
        location: _point(b.latitude, b.longitude),
        business: b,
        businessCategory: businesses.categoryOf(b),
      ),
    for (final pl in places?.places ?? const <Place>[])
      PointOfInterest(
        id: 'place:${pl.id}',
        kind: PointKind.place,
        title: pl.title,
        subtitle: pl.summary,
        location: _point(pl.latitude, pl.longitude),
        place: pl,
      ),
  ];
}

/// Tüm veriler (yüklenmiş olanlar) tek listede.
final pointsProvider = Provider.family<List<PointOfInterest>, String>((ref, pharmacyLabel) {
  final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
  return collectPoints(
    erdekNow: now,
    pharmacyLabel: pharmacyLabel,
    pharmacy: ref.watch(pharmacyDataProvider).value?.data,
    businesses: ref.watch(businessesDataProvider).value?.data,
    places: ref.watch(placesDataProvider).value?.data,
  );
});

/// Yakından uzağa; konumu olmayanlar sona.
List<(PointOfInterest, double?)> sortByDistance(List<PointOfInterest> points, GeoPoint from) {
  final withDistance = [for (final p in points) (p, p.location?.distanceTo(from))];
  withDistance.sort((a, b) {
    final da = a.$2;
    final db = b.$2;
    if (da == null && db == null) return a.$1.title.compareTo(b.$1.title);
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  });
  return withDistance;
}
