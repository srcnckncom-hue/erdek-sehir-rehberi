import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/data_result.dart';
import '../../core/util/text_search.dart';
import '../reminders/reminder_scheduler.dart';

/// Kesinti türü (panelde seçilir). Bilinmeyen → [other].
enum OutageType {
  water('su'),
  electricity('elektrik'),
  gas('dogalgaz'),
  road('yol'),
  other('diger');

  const OutageType(this.jsonValue);

  final String jsonValue;

  static OutageType fromJson(String? v) =>
      OutageType.values.where((t) => t.jsonValue == v).firstOrNull ?? OutageType.other;
}

/// Planlı ya da arıza kaynaklı kesinti (data/outages.json). Saatler Erdek saati.
@immutable
class Outage {
  const Outage({
    required this.id,
    required this.type,
    required this.areas,
    required this.startsAt,
    this.endsAt,
    this.reason,
    this.source,
    this.note,
  });

  factory Outage.fromJson(Map<String, dynamic> json) => Outage(
        id: json['id'] as String,
        type: OutageType.fromJson(json['type'] as String?),
        areas: [
          for (final a in json['areas'] as List<dynamic>? ?? const []) ?_text(a),
        ],
        startsAt: DateTime.parse(json['startsAt'] as String),
        endsAt: switch (_text(json['endsAt'])) {
          final e? => DateTime.parse(e),
          _ => null,
        },
        reason: _text(json['reason']),
        source: _text(json['source']),
        note: _text(json['note']),
      );

  final String id;
  final OutageType type;

  /// Etkilenen mahalleler; boşsa "tüm Erdek".
  final List<String> areas;
  final DateTime startsAt;

  /// Bilinmiyorsa null (arıza; "giderilene kadar").
  final DateTime? endsAt;
  final String? reason;

  /// Duyuruyu yapan kurum (BASKİ, UEDAŞ…).
  final String? source;
  final String? note;

  /// Bitiş bilinmiyorsa başlangıçtan 12 saat sonra listeden kalkar.
  DateTime get effectiveEnd => endsAt ?? startsAt.add(const Duration(hours: 12));

  bool isOverAt(DateTime now) => !now.isBefore(effectiveEnd);
  bool isActiveAt(DateTime now) => !now.isBefore(startsAt) && !isOverAt(now);

  bool get isCitywide => areas.isEmpty;

  /// [area] mahallesini etkiliyor mu (Türkçe harf / büyük-küçük farkı yok).
  bool affects(String? area) {
    if (area == null) return false;
    if (isCitywide) return true;
    final key = normalizeArea(area);
    return areas.any((a) => normalizeArea(a) == key);
  }
}

/// "Cumhuriyet Mah." = "cumhuriyet mahallesi" = "Cumhuriyet".
String normalizeArea(String area) => TextSearch.normalize(area)
    .replaceAll(RegExp(r'(?<![a-z])(mahallesi|mahalle|mah|mh)(?![a-z])'), '')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

class OutagesData {
  const OutagesData({this.areas = const [], this.outages = const []});

  factory OutagesData.fromJson(Map<String, dynamic> json) => OutagesData(
        areas: [
          for (final a in json['areas'] as List<dynamic>? ?? const []) ?_text(a),
        ],
        outages: [
          for (final o in json['outages'] as List<dynamic>? ?? const [])
            Outage.fromJson(o as Map<String, dynamic>),
        ],
      );

  /// Panelde tanımlı mahalleler ("Mahallem" seçimi için).
  final List<String> areas;
  final List<Outage> outages;

  /// Bitmemiş kesintiler: önce sürenler, sonra başlangıca göre.
  List<Outage> current(DateTime now) => [for (final o in outages) if (!o.isOverAt(now)) o]
    ..sort((a, b) {
      final aa = a.isActiveAt(now);
      final bb = b.isActiveAt(now);
      if (aa != bb) return aa ? -1 : 1;
      return a.startsAt.compareTo(b.startsAt);
    });

  /// Seçilebilir mahalleler: paneldeki liste + kesintilerde geçenler (tekrarsız, A–Z).
  List<String> allAreas() {
    final byKey = <String, String>{};
    for (final a in [...areas, for (final o in outages) ...o.areas]) {
      byKey.putIfAbsent(normalizeArea(a), () => a);
    }
    return byKey.values.toList()..sort((a, b) => TextSearch.normalize(a).compareTo(TextSearch.normalize(b)));
  }

  /// Ana sayfa uyarısı: süren ya da 24 saat içinde başlayan; mahallemi etkileyen öne.
  Outage? headline(DateTime now, String? myArea) {
    final soon = [
      for (final o in current(now))
        if (o.isActiveAt(now) || o.startsAt.difference(now) <= const Duration(hours: 24)) o,
    ];
    if (soon.isEmpty) return null;
    if (myArea != null) {
      final mine = soon.where((o) => o.affects(myArea)).firstOrNull;
      if (mine != null) return mine;
    }
    return soon.first;
  }
}

String? _text(Object? v) {
  final t = (v as String?)?.trim();
  return t == null || t.isEmpty ? null : t;
}

final outagesDataProvider = StreamProvider<DataResult<OutagesData>>(
  (ref) => ref.watch(offlineFirstLoaderProvider).watch('outages.json', OutagesData.fromJson),
);

// ─── Mahallem + hatırlatma (cihazda) ─────────────────────────────────────

/// Kullanıcının seçtiği mahalle (null = seçilmedi).
final myAreaProvider = NotifierProvider<MyAreaNotifier, String?>(MyAreaNotifier.new);

class MyAreaNotifier extends Notifier<String?> {
  static const storeKey = 'my_area';

  @override
  String? build() => _text(ref.watch(reminderStoreProvider).read(storeKey));

  Future<void> set(String? area) async {
    state = _text(area);
    await ref.read(reminderStoreProvider).write(storeKey, state);
  }
}

/// "Mahallemdeki kesintileri 1 saat önce hatırlat" açık mı.
final outageRemindersProvider = NotifierProvider<OutageRemindersNotifier, bool>(OutageRemindersNotifier.new);

class OutageRemindersNotifier extends Notifier<bool> {
  static const storeKey = 'outage_reminders';

  @override
  bool build() => ref.watch(reminderStoreProvider).read(storeKey) == 'true';

  /// Açarken bildirim izni ister; verilmezse false döner.
  Future<bool> setEnabled(bool on) async {
    if (on && !await ref.read(reminderSchedulerProvider).requestPermission()) return false;
    state = on;
    await ref.read(reminderStoreProvider).write(storeKey, '$on');
    return true;
  }
}

/// Mahallemi etkileyen planlı kesintilere, başlamadan 1 saat önce yerel bildirim.
/// Her seferinde aralığı silip yeniden kurar (en fazla [maxCount]).
Future<void> syncOutageReminders({
  required ReminderScheduler scheduler,
  required OutagesData? data,
  required String? myArea,
  required bool enabled,
  required DateTime erdekNow,
  required String Function(Outage) title,
  required String Function(Outage) body,
  int maxCount = 10,
}) async {
  await scheduler.cancelRange(NotificationIds.outageBase, NotificationIds.outageEnd);
  if (!enabled || data == null || myArea == null) return;
  var id = NotificationIds.outageBase;
  for (final o in data.current(erdekNow)) {
    if (id - NotificationIds.outageBase >= maxCount) break;
    final at = o.startsAt.subtract(const Duration(hours: 1));
    if (!o.affects(myArea) || !at.isAfter(erdekNow)) continue;
    await scheduler.schedule(id: id++, erdekAt: at, title: title(o), body: body(o));
  }
}
