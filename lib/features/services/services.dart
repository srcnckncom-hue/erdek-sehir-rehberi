import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/data_result.dart';

/// Haritadaki hizmet noktası türü (panelde seçilir). Adlar MapLayer ile aynı.
enum ServiceType {
  taxi('taksi'),
  atm('atm'),
  parking('otopark'),
  wc('wc'),
  charging('sarj'),
  fuel('akaryakit');

  const ServiceType(this.jsonValue);

  final String jsonValue;

  static ServiceType? fromJson(String? v) => values.where((t) => t.jsonValue == v).firstOrNull;
}

/// Taksi durağı, ATM, otopark, WC, şarj istasyonu, akaryakıt (data/services.json).
@immutable
class ServicePoint {
  const ServicePoint({
    required this.id,
    required this.type,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.note,
    this.hours,
    this.phone,
  });

  final String id;
  final ServiceType type;
  final String name;
  final double latitude;
  final double longitude;

  /// "Ziraat, İş Bankası" (ATM), "Ücretli" (otopark), "22 kW" (şarj)…
  final String? note;
  final String? hours;
  final String? phone;

  static ServicePoint? fromJson(Map<String, dynamic> json) {
    final type = ServiceType.fromJson(json['type'] as String?);
    if (type == null) return null;
    return ServicePoint(
      id: json['id'] as String,
      type: type,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      note: _text(json['note']),
      hours: _text(json['hours']),
      phone: _text(json['phone']),
    );
  }
}

class ServicesData {
  const ServicesData({required this.points});

  factory ServicesData.fromJson(Map<String, dynamic> json) => ServicesData(
        points: [
          for (final p in json['points'] as List<dynamic>? ?? const []) ?ServicePoint.fromJson(p as Map<String, dynamic>),
        ],
      );

  final List<ServicePoint> points;
}

String? _text(Object? v) {
  final t = (v as String?)?.trim();
  return t == null || t.isEmpty ? null : t;
}

final servicesDataProvider = StreamProvider<DataResult<ServicesData>>(
  (ref) => ref.watch(offlineFirstLoaderProvider).watch('services.json', ServicesData.fromJson),
);
