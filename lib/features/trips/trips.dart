import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/data_result.dart';
import '../explore/domain/explore.dart';
import '../nearby/location_service.dart';

enum TripType {
  walk('yuruyus'),
  bike('bisiklet'),
  boat('tekne'),
  car('arac'),
  culture('tarih');

  const TripType(this.jsonValue);

  final String jsonValue;

  static TripType fromJson(String? v) => values.where((t) => t.jsonValue == v).firstOrNull ?? TripType.walk;

  /// Google Haritalar yol tarifi kipi.
  String get travelMode => switch (this) {
        TripType.walk || TripType.culture => 'walking',
        TripType.bike => 'bicycling',
        TripType.car || TripType.boat => 'driving',
      };
}

enum TripDifficulty {
  easy('kolay'),
  medium('orta'),
  hard('zor');

  const TripDifficulty(this.jsonValue);

  final String jsonValue;

  static TripDifficulty? fromJson(String? v) => values.where((d) => d.jsonValue == v).firstOrNull;
}

@immutable
class TripStop {
  const TripStop({required this.name, this.location, this.note});

  factory TripStop.fromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num?)?.toDouble();
    final lng = (json['longitude'] as num?)?.toDouble();
    return TripStop(
      name: json['name'] as String,
      location: lat == null || lng == null ? null : GeoPoint(lat, lng),
      note: _text(json['note']),
    );
  }

  final String name;
  final GeoPoint? location;
  final String? note;
}

/// Panelden eklenen gezi rotası (data/trips.json).
@immutable
class TripRoute {
  const TripRoute({
    required this.id,
    required this.title,
    required this.type,
    required this.summary,
    this.difficulty,
    this.distanceKm,
    this.durationMin,
    this.season,
    this.paragraphs = const [],
    this.tips = const [],
    this.stops = const [],
    this.path = const [],
    this.photos = const [],
  });

  factory TripRoute.fromJson(Map<String, dynamic> json) => TripRoute(
        id: json['id'] as String,
        title: json['title'] as String,
        type: TripType.fromJson(json['type'] as String?),
        summary: json['summary'] as String,
        difficulty: TripDifficulty.fromJson(json['difficulty'] as String?),
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        durationMin: json['durationMin'] as int?,
        season: _text(json['season']),
        paragraphs: [for (final p in json['paragraphs'] as List<dynamic>? ?? const []) ?_text(p)],
        tips: [for (final t in json['tips'] as List<dynamic>? ?? const []) ?_text(t)],
        stops: [
          for (final s in json['stops'] as List<dynamic>? ?? const []) TripStop.fromJson(s as Map<String, dynamic>),
        ],
        path: [
          for (final pt in json['path'] as List<dynamic>? ?? const [])
            if (pt case [final num lat, final num lng]) GeoPoint(lat.toDouble(), lng.toDouble()),
        ],
        photos: [
          for (final p in json['photos'] as List<dynamic>? ?? const []) PlacePhoto.fromJson(p as Map<String, dynamic>),
        ],
      );

  final String id;
  final String title;
  final TripType type;
  final String summary;
  final TripDifficulty? difficulty;
  final double? distanceKm;
  final int? durationMin;

  /// "En güzel: Nisan–Haziran" gibi serbest metin.
  final String? season;
  final List<String> paragraphs;
  final List<String> tips;
  final List<TripStop> stops;

  /// İsteğe bağlı rota çizgisi; yoksa duraklar sırayla birleştirilir.
  final List<GeoPoint> path;
  final List<PlacePhoto> photos;

  List<GeoPoint> get stopPoints => [for (final s in stops) ?s.location];
  List<GeoPoint> get line => path.length > 1 ? path : stopPoints;
  bool get hasMap => stopPoints.isNotEmpty || path.length > 1;

  /// Google Haritalar'da duraklar arası yol tarifi (en fazla 9 ara durak).
  String? directionsUrl() {
    final pts = stopPoints;
    if (pts.isEmpty) return null;
    String f(GeoPoint p) => '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}';
    final middle = pts.length > 2 ? pts.sublist(1, pts.length - 1).take(9).map(f).join('|') : null;
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      if (pts.length > 1) 'origin': f(pts.first),
      'destination': f(pts.last),
      'waypoints': ?middle,
      'travelmode': type.travelMode,
    }).toString();
  }
}

class TripsData {
  const TripsData({required this.trips});

  factory TripsData.fromJson(Map<String, dynamic> json) => TripsData(
        trips: [for (final t in json['trips'] as List<dynamic>? ?? const []) TripRoute.fromJson(t as Map<String, dynamic>)],
      );

  final List<TripRoute> trips;

  List<TripType> types() {
    final used = {for (final t in trips) t.type};
    return [for (final t in TripType.values) if (used.contains(t)) t];
  }
}

String? _text(Object? v) {
  final t = (v as String?)?.trim();
  return t == null || t.isEmpty ? null : t;
}

final tripsDataProvider = StreamProvider<DataResult<TripsData>>(
  (ref) => ref.watch(offlineFirstLoaderProvider).watch('trips.json', TripsData.fromJson),
);
