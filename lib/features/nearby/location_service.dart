import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/device.dart';

/// Enlem/boylam.
@immutable
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// İki nokta arası kuş uçuşu mesafe (metre, haversine).
  double distanceTo(GeoPoint other) {
    const earthRadius = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(other.latitude - latitude);
    final dLng = rad(other.longitude - longitude);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(latitude)) * math.cos(rad(other.latitude)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadius * math.asin(math.sqrt(a));
  }
}

enum LocationFailure { denied, unavailable }

class LocationException implements Exception {
  const LocationException(this.failure);

  final LocationFailure failure;
}

/// Konum: yalnızca kullanıcı "Yakınımdakiler"i açınca, bir kez sorulur.
/// Konum telefonda kalır; hiçbir yere gönderilmez ya da kaydedilmez.
abstract interface class LocationService {
  /// İzin yoksa iOS izin penceresini gösterir. Hata: [LocationException].
  Future<GeoPoint> current();
}

/// iOS: AppDelegate'teki 'erdek/location' kanalı (CoreLocation).
/// Android: MainActivity'deki aynı kanal (LocationManager).
class ChannelLocationService implements LocationService {
  static const _channel = MethodChannel('erdek/location');

  @override
  Future<GeoPoint> current() async {
    if (!isAndroidDevice && (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS)) {
      throw const LocationException(LocationFailure.unavailable);
    }
    try {
      final result = await _channel
          .invokeMapMethod<String, Object?>('current')
          .timeout(const Duration(seconds: 20));
      final lat = (result?['lat'] as num?)?.toDouble();
      final lng = (result?['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) throw const LocationException(LocationFailure.unavailable);
      return GeoPoint(lat, lng);
    } on PlatformException catch (e) {
      throw LocationException(e.code == 'denied' ? LocationFailure.denied : LocationFailure.unavailable);
    } on MissingPluginException {
      throw const LocationException(LocationFailure.unavailable);
    } on LocationException {
      rethrow;
    } catch (_) {
      throw const LocationException(LocationFailure.unavailable);
    }
  }
}

/// Testler: sabit konum (null → izin yok).
class FakeLocationService implements LocationService {
  const FakeLocationService(this.point);

  final GeoPoint? point;

  @override
  Future<GeoPoint> current() async =>
      point ?? (throw const LocationException(LocationFailure.denied));
}

final locationServiceProvider = Provider<LocationService>((ref) => ChannelLocationService());

/// Erdek merkez (harita başlangıcı).
const erdekCenter = GeoPoint(40.3955, 27.7930);

/// "350 m", "1,2 km", "12 km"
String formatDistance(double meters, {String decimalSeparator = ','}) {
  if (meters < 1000) return '${(meters / 10).round() * 10} m';
  final km = meters / 1000;
  if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', decimalSeparator)} km';
  return '${km.round()} km';
}
