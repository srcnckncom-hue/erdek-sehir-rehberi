/// Reklam alanı (ad_slots).
class AdSlotInfo {
  const AdSlotInfo({required this.id, required this.title, this.description});

  factory AdSlotInfo.fromJson(Map<String, dynamic> j) => AdSlotInfo(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
      );

  final String id;
  final String title;
  final String? description;
}

/// Reklam (ads + ad_placements).
class AdItem {
  const AdItem({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.startsAt,
    required this.isActive,
    required this.priority,
    required this.slotIds,
    this.advertiser,
    this.linkUrl,
    this.endsAt,
  });

  factory AdItem.fromJson(Map<String, dynamic> j) => AdItem(
        id: j['id'] as String,
        title: j['title'] as String,
        advertiser: j['advertiser'] as String?,
        imagePath: j['image_path'] as String,
        linkUrl: j['link_url'] as String?,
        startsAt: DateTime.parse(j['starts_at'] as String),
        endsAt: j['ends_at'] == null ? null : DateTime.parse(j['ends_at'] as String),
        isActive: j['is_active'] as bool,
        priority: (j['priority'] as num).toInt(),
        slotIds: [
          for (final p in (j['ad_placements'] as List<dynamic>? ?? const []))
            (p as Map<String, dynamic>)['slot_id'] as String,
        ],
      );

  final String id;
  final String title;
  final String? advertiser;
  final String imagePath;
  final String? linkUrl;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final int priority;
  final List<String> slotIds;

  /// Şu an uygulamada görünüyor mu?
  bool isLive(DateTime now) =>
      isActive && slotIds.isNotEmpty && !startsAt.isAfter(now) && (endsAt == null || endsAt!.isAfter(now));
}

/// Günlük sayaç satırı (ad_stats_daily).
class AdStat {
  const AdStat({
    required this.adId,
    required this.slotId,
    required this.day,
    required this.impressions,
    required this.clicks,
  });

  factory AdStat.fromJson(Map<String, dynamic> j) => AdStat(
        adId: j['ad_id'] as String,
        slotId: j['slot_id'] as String,
        day: j['day'] as String,
        impressions: (j['impressions'] as num).toInt(),
        clicks: (j['clicks'] as num).toInt(),
      );

  final String adId;
  final String slotId;

  /// YYYY-MM-DD (Türkiye saatiyle gün)
  final String day;
  final int impressions;
  final int clicks;
}

/// Tarih yardımcıları: panelde tarihler Türkiye saatiyle (UTC+3) seçilir.
abstract final class TrDate {
  static const _offset = Duration(hours: 3);

  /// Seçilen günün 00:00'ı (TR) → ISO metin.
  static String startOfDay(DateTime day) => _iso(DateTime.utc(day.year, day.month, day.day));

  /// Seçilen günün 23:59:59'u (TR) → ISO metin.
  static String endOfDay(DateTime day) =>
      _iso(DateTime.utc(day.year, day.month, day.day, 23, 59, 59));

  static String _iso(DateTime trWallClockAsUtc) => trWallClockAsUtc.subtract(_offset).toIso8601String();

  /// UTC zaman → TR takvim günü.
  static DateTime toTrDay(DateTime utc) {
    final t = utc.toUtc().add(_offset);
    return DateTime(t.year, t.month, t.day);
  }

  static String format(DateTime utc) {
    final d = toTrDay(utc);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }
}
