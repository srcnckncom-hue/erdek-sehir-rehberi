enum AnnouncementCategory {
  outage('kesinti'),
  market('pazar'),
  event('etkinlik'),
  general('genel');

  const AnnouncementCategory(this.jsonValue);

  final String jsonValue;

  /// Bilinmeyen kategori uygulamayı bozmasın: "genel" sayılır.
  static AnnouncementCategory fromJson(String? value) =>
      values.where((c) => c.jsonValue == value).firstOrNull ?? general;
}

class Announcement {
  const Announcement({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.publishedAt,
    this.startsAt,
    this.endsAt,
    this.link,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        category: AnnouncementCategory.fromJson(json['category'] as String?),
        title: json['title'] as String,
        body: json['body'] as String,
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        startsAt: _date(json['startsAt']),
        endsAt: _date(json['endsAt']),
        link: json['link'] as String?,
      );

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  final String id;
  final AnnouncementCategory category;
  final String title;
  final String body;
  final DateTime publishedAt;

  /// Kesinti/etkinlik başlangıcı (opsiyonel).
  final DateTime? startsAt;

  /// Bu andan sonra liste dışı kalır (opsiyonel).
  final DateTime? endsAt;
  final String? link;

  bool isActiveAt(DateTime now) => endsAt == null || endsAt!.isAfter(now);
}

class AnnouncementsData {
  const AnnouncementsData({required this.items});

  factory AnnouncementsData.fromJson(Map<String, dynamic> json) =>
      AnnouncementsData(
        items: (json['items'] as List<dynamic>)
            .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final List<Announcement> items;

  /// Süresi dolmamış duyurular, en yeni üstte.
  List<Announcement> activeAt(DateTime now) =>
      items.where((a) => a.isActiveAt(now)).toList()
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
}
