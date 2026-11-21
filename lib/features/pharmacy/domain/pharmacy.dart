import '../../../core/time/calendar_date.dart';

class Pharmacy {
  const Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.latitude,
    this.longitude,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) => Pharmacy(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        phone: json['phone'] as String,
        latitude: (json['lat'] as num?)?.toDouble(),
        longitude: (json['lng'] as num?)?.toDouble(),
      );

  final String id;
  final String name;
  final String address;

  /// E.164 biçiminde, ör. +902660000000 (tel: bağlantısı için).
  final String phone;
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;
}

/// Bir nöbet günü: [date] 08:30'dan ertesi gün 08:30'a kadar.
class PharmacyDuty {
  const PharmacyDuty({required this.date, required this.pharmacyIds, this.notes = const {}});

  factory PharmacyDuty.fromJson(Map<String, dynamic> json) => PharmacyDuty(
        date: CalendarDate.parse(json['date'] as String),
        pharmacyIds: (json['pharmacyIds'] as List<dynamic>).cast<String>(),
        notes: (json['notes'] as Map<String, dynamic>? ?? const {}).cast<String, String>(),
      );

  final CalendarDate date;
  final List<String> pharmacyIds;

  /// Eczane kimliği → o güne özel not ("Gece 22:00'a kadar nöbetçidir.").
  final Map<String, String> notes;
}

class PharmacyData {
  const PharmacyData({required this.pharmacies, required this.duties});

  factory PharmacyData.fromJson(Map<String, dynamic> json) => PharmacyData(
        pharmacies: (json['pharmacies'] as List<dynamic>)
            .map((e) => Pharmacy.fromJson(e as Map<String, dynamic>))
            .toList(),
        duties: (json['duties'] as List<dynamic>)
            .map((e) => PharmacyDuty.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final List<Pharmacy> pharmacies;
  final List<PharmacyDuty> duties;

  /// [dutyDate] nöbet gününde nöbetçi olan eczaneler. Liste yoksa boş döner.
  List<Pharmacy> onDutyFor(CalendarDate dutyDate) {
    final duty = duties.where((d) => d.date == dutyDate).firstOrNull;
    if (duty == null) return const [];
    final byId = {for (final p in pharmacies) p.id: p};
    return [
      for (final id in duty.pharmacyIds) ?byId[id],
    ];
  }

  /// [dutyDate] gününde [pharmacyId] için özel not (yoksa null).
  String? noteFor(CalendarDate dutyDate, String pharmacyId) =>
      duties.where((d) => d.date == dutyDate).firstOrNull?.notes[pharmacyId];

  /// Listede kayıtlı son nöbet günü (veri ne zamana kadar dolu?).
  CalendarDate? get lastDutyDate => duties.isEmpty
      ? null
      : duties.map((d) => d.date).reduce((a, b) => a.isAfter(b) ? a : b);
}
