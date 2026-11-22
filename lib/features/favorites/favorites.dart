import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../businesses/data/businesses_repository.dart';
import '../businesses/domain/business.dart';
import '../explore/data/explore_repository.dart';
import '../explore/domain/explore.dart';
import '../nearby/location_service.dart';
import '../nearby/points.dart';
import '../pharmacy/data/pharmacy_repository.dart';
import '../pharmacy/domain/duty_schedule.dart';
import '../pharmacy/domain/pharmacy.dart';
import '../reminders/reminder_scheduler.dart';

/// Favori anahtarları: "business:ID", "place:ID", "pharmacy:ID"
/// (PointOfInterest.id ile aynı). Cihazda saklanır, hiçbir yere gönderilmez.
abstract final class FavoriteKeys {
  static String business(Business b) => 'business:${b.id}';
  static String place(Place p) => 'place:${p.id}';
  static String pharmacy(Pharmacy p) => 'pharmacy:${p.id}';
}

/// Favoriler, en son eklenen başta. En fazla [maxCount].
final favoritesProvider = NotifierProvider<FavoritesNotifier, List<String>>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<List<String>> {
  static const storeKey = 'favorites';
  static const maxCount = 100;

  @override
  List<String> build() {
    final raw = ref.watch(reminderStoreProvider).read(storeKey);
    if (raw == null) return const [];
    try {
      return [for (final v in jsonDecode(raw) as List<dynamic>) v as String];
    } catch (_) {
      return const [];
    }
  }

  bool contains(String key) => state.contains(key);

  /// Ekler ya da çıkarır. Eklendiyse true.
  Future<bool> toggle(String key) async {
    final added = !state.contains(key);
    final next = added ? [key, ...state].take(maxCount).toList() : [...state.where((k) => k != key)];
    state = next;
    await ref.read(reminderStoreProvider).write(storeKey, jsonEncode(next));
    return added;
  }
}

/// Favorilerin güncel kayıtları (silinmiş yerler atlanır, sıra korunur).
/// Eczanenin alt başlığı: bugün nöbetçiyse [onDutyLabel], değilse adresi.
List<PointOfInterest> resolveFavorites({
  required List<String> keys,
  required DateTime erdekNow,
  required String onDutyLabel,
  PharmacyData? pharmacy,
  BusinessesData? businesses,
  PlacesData? places,
}) {
  GeoPoint? point(double? lat, double? lng) => lat == null || lng == null ? null : GeoPoint(lat, lng);
  final onDuty = {for (final p in pharmacy?.onDutyFor(dutyDateFor(erdekNow)) ?? const <Pharmacy>[]) p.id};
  final result = <PointOfInterest>[];
  for (final key in keys) {
    final sep = key.indexOf(':');
    if (sep < 0) continue;
    final kind = key.substring(0, sep);
    final id = key.substring(sep + 1);
    switch (kind) {
      case 'business':
        final b = businesses?.businesses.where((e) => e.id == id).firstOrNull;
        if (b == null) continue;
        final category = businesses!.categoryOf(b);
        result.add(PointOfInterest(
          id: key,
          kind: PointKind.business,
          title: b.name,
          subtitle: category?.title,
          location: point(b.latitude, b.longitude),
          business: b,
          businessCategory: category,
        ));
      case 'place':
        final pl = places?.places.where((e) => e.id == id).firstOrNull;
        if (pl == null) continue;
        result.add(PointOfInterest(
          id: key,
          kind: PointKind.place,
          title: pl.title,
          subtitle: pl.summary,
          location: point(pl.latitude, pl.longitude),
          place: pl,
        ));
      case 'pharmacy':
        final ph = pharmacy?.pharmacies.where((e) => e.id == id).firstOrNull;
        if (ph == null) continue;
        result.add(PointOfInterest(
          id: key,
          kind: PointKind.pharmacy,
          title: ph.name,
          subtitle: onDuty.contains(ph.id) ? onDutyLabel : ph.address,
          location: point(ph.latitude, ph.longitude),
          pharmacy: ph,
        ));
    }
  }
  return result;
}

final favoriteItemsProvider = Provider.family<List<PointOfInterest>, String>((ref, onDutyLabel) {
  final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
  return resolveFavorites(
    keys: ref.watch(favoritesProvider),
    erdekNow: now,
    onDutyLabel: onDutyLabel,
    pharmacy: ref.watch(pharmacyDataProvider).value?.data,
    businesses: ref.watch(businessesDataProvider).value?.data,
    places: ref.watch(placesDataProvider).value?.data,
  );
});
