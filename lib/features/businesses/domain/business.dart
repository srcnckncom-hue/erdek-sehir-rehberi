import '../../explore/domain/explore.dart';

/// Kategori ikonu (panelde listeden seçilir). Bilinmeyen değer → [other].
enum BusinessIcon {
  food('food'),
  cafe('cafe'),
  hotel('hotel'),
  market('market'),
  shopping('shopping'),
  service('service'),
  car('car'),
  health('health'),
  beauty('beauty'),
  other('other');

  const BusinessIcon(this.jsonValue);

  final String jsonValue;

  static BusinessIcon fromJson(String? value) =>
      values.firstWhere((i) => i.jsonValue == value, orElse: () => other);
}

/// İşletme kategorisi (panelden eklenir: "Yeme-İçme", "Konaklama" ...).
class BusinessCategory {
  const BusinessCategory({required this.id, required this.title, this.icon = BusinessIcon.other});

  factory BusinessCategory.fromJson(Map<String, dynamic> json) => BusinessCategory(
        id: json['id'] as String,
        title: json['title'] as String,
        icon: BusinessIcon.fromJson(json['icon'] as String?),
      );

  final String id;
  final String title;
  final BusinessIcon icon;
}

class Business {
  const Business({
    required this.id,
    required this.name,
    required this.categoryId,
    this.summary,
    this.description,
    this.phone,
    this.whatsapp,
    this.address,
    this.latitude,
    this.longitude,
    this.website,
    this.instagram,
    this.hours,
    this.photos = const [],
  });

  factory Business.fromJson(Map<String, dynamic> json) => Business(
        id: json['id'] as String,
        name: json['name'] as String,
        categoryId: json['categoryId'] as String,
        summary: _text(json['summary']),
        description: _text(json['description']),
        phone: _text(json['phone']),
        whatsapp: _text(json['whatsapp']),
        address: _text(json['address']),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        website: _text(json['website']),
        instagram: _text(json['instagram']),
        hours: _text(json['hours']),
        photos: [
          for (final p in json['photos'] as List<dynamic>? ?? const [])
            PlacePhoto.fromJson(p as Map<String, dynamic>),
        ],
      );

  /// Boş metni yok sayar.
  static String? _text(Object? value) {
    final text = (value as String?)?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  final String id;
  final String name;
  final String categoryId;

  /// Listede görünen kısa tanım ("Ev yemekleri, balık").
  final String? summary;

  /// Ayrıntı sayfasındaki metin (paragraflar boş satırla ayrılır).
  final String? description;

  /// "+902661234567" biçiminde.
  final String? phone;
  final String? whatsapp;
  final String? address;
  final double? latitude;
  final double? longitude;

  /// https:// ile başlayan adresler.
  final String? website;
  final String? instagram;

  /// Serbest metin: "Her gün 09:00–23:00".
  final String? hours;

  /// İlki kapak fotoğrafıdır.
  final List<PlacePhoto> photos;

  bool get hasLocation => (latitude != null && longitude != null) || address != null;

  List<String> get paragraphs => description == null
      ? const []
      : description!
          .split(RegExp(r'\n\s*\n'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
}

class BusinessesData {
  const BusinessesData({required this.categories, required this.businesses});

  factory BusinessesData.fromJson(Map<String, dynamic> json) => BusinessesData(
        categories: [
          for (final c in json['categories'] as List<dynamic>? ?? const [])
            BusinessCategory.fromJson(c as Map<String, dynamic>),
        ],
        businesses: [
          for (final b in json['businesses'] as List<dynamic>? ?? const [])
            Business.fromJson(b as Map<String, dynamic>),
        ],
      );

  final List<BusinessCategory> categories;
  final List<Business> businesses;

  BusinessCategory? categoryOf(Business business) {
    for (final c in categories) {
      if (c.id == business.categoryId) return c;
    }
    return null;
  }

  /// İçinde en az bir işletme olan kategoriler (panel sırasıyla).
  List<BusinessCategory> get usedCategories {
    final used = {for (final b in businesses) b.categoryId};
    return [for (final c in categories) if (used.contains(c.id)) c];
  }

  /// [categoryId] null ise hepsi. Panel sırası korunur.
  List<Business> filter({String? categoryId}) => [
        for (final b in businesses)
          if (categoryId == null || b.categoryId == categoryId) b,
      ];

  int countIn(String categoryId) => businesses.where((b) => b.categoryId == categoryId).length;
}
