/// Bir slotta yayında olan reklam (Supabase get_active_ads() satırı).
class Ad {
  const Ad({
    required this.id,
    required this.slotId,
    required this.title,
    required this.imagePath,
    this.advertiser,
    this.linkUrl,
    this.priority = 0,
    this.endsAt,
  });

  factory Ad.fromJson(Map<String, dynamic> json) => Ad(
        id: json['ad_id'] as String,
        slotId: json['slot_id'] as String,
        title: json['title'] as String,
        advertiser: json['advertiser'] as String?,
        imagePath: json['image_path'] as String,
        linkUrl: json['link_url'] as String?,
        priority: (json['priority'] as num?)?.toInt() ?? 0,
        endsAt: json['ends_at'] == null ? null : DateTime.parse(json['ends_at'] as String),
      );

  final String id;
  final String slotId;
  final String title;
  final String? advertiser;

  /// ad-images kovasındaki dosya yolu.
  final String imagePath;
  final String? linkUrl;
  final int priority;
  final DateTime? endsAt;

  bool isLiveAt(DateTime now) => endsAt == null || endsAt!.isAfter(now);
}

enum AdEventKind { impression, click }

/// Slot için gösterilecek reklamı seçer: en yüksek öncelikli reklamlar
/// arasında [rotation] ile sırayla döner (oturum başına farklı reklam).
Ad? pickAd(List<Ad> ads, String slotId, {required DateTime now, int rotation = 0}) {
  final candidates = [
    for (final ad in ads)
      if (ad.slotId == slotId && ad.isLiveAt(now)) ad,
  ];
  if (candidates.isEmpty) return null;
  final top = candidates.map((a) => a.priority).reduce((a, b) => a > b ? a : b);
  final best = [for (final ad in candidates) if (ad.priority == top) ad];
  return best[rotation.abs() % best.length];
}
