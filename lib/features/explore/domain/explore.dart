/// Gezilecek yerin bulunduğu bölge.
enum PlaceArea {
  erdek('erdek'),
  kapidag('kapidag');

  const PlaceArea(this.jsonValue);

  final String jsonValue;

  static PlaceArea fromJson(String value) =>
      values.firstWhere((a) => a.jsonValue == value, orElse: () => erdek);
}

/// Yer türü (ikon ve filtre için). Metinleri arb'de: placeCategoryName.
enum PlaceCategory {
  beach('plaj'),
  history('tarihi'),
  nature('doga'),
  village('koy'),
  viewpoint('manzara'),
  other('diger');

  const PlaceCategory(this.jsonValue);

  final String jsonValue;

  static PlaceCategory fromJson(String value) =>
      values.firstWhere((c) => c.jsonValue == value, orElse: () => other);
}

class Place {
  const Place({
    required this.id,
    required this.title,
    required this.area,
    required this.category,
    required this.summary,
    required this.paragraphs,
    this.tips = const [],
    this.address,
    this.latitude,
    this.longitude,
  });

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as String,
        title: json['title'] as String,
        area: PlaceArea.fromJson(json['area'] as String),
        category: PlaceCategory.fromJson(json['category'] as String),
        summary: json['summary'] as String,
        paragraphs: (json['paragraphs'] as List<dynamic>).cast<String>(),
        tips: (json['tips'] as List<dynamic>? ?? const []).cast<String>(),
        address: json['address'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  final String id;
  final String title;
  final PlaceArea area;
  final PlaceCategory category;

  /// Listede görünen 1–2 cümlelik özet.
  final String summary;

  /// Ayrıntı sayfasındaki metin (paragraf paragraf).
  final List<String> paragraphs;

  /// Kısa pratik bilgiler ("Yaz aylarında kalabalık olur" gibi).
  final List<String> tips;
  final String? address;
  final double? latitude;
  final double? longitude;

  bool get hasLocation => (latitude != null && longitude != null) || address != null;
}

class PlacesData {
  const PlacesData({required this.places});

  factory PlacesData.fromJson(Map<String, dynamic> json) => PlacesData(
        places: (json['places'] as List<dynamic>)
            .map((e) => Place.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final List<Place> places;

  /// Filtre: bölge ve/veya tür (null = hepsi). Dosyadaki sıra korunur.
  List<Place> filter({PlaceArea? area, PlaceCategory? category}) => [
        for (final p in places)
          if ((area == null || p.area == area) && (category == null || p.category == category)) p,
      ];

  /// Verilen bölgede bulunan türler (filtre hapları için), enum sırasıyla.
  List<PlaceCategory> categoriesIn(PlaceArea? area) {
    final present = {for (final p in filter(area: area)) p.category};
    return [for (final c in PlaceCategory.values) if (present.contains(c)) c];
  }
}

/// Erdek tarihinden bir dönem.
class HistorySection {
  const HistorySection({
    required this.id,
    required this.title,
    required this.paragraphs,
    this.period,
  });

  factory HistorySection.fromJson(Map<String, dynamic> json) => HistorySection(
        id: json['id'] as String,
        title: json['title'] as String,
        period: json['period'] as String?,
        paragraphs: (json['paragraphs'] as List<dynamic>).cast<String>(),
      );

  final String id;
  final String title;

  /// Zaman aralığı metni ("MÖ 7. yüzyıl" gibi).
  final String? period;
  final List<String> paragraphs;
}

class HistoryData {
  const HistoryData({required this.sections, this.intro});

  factory HistoryData.fromJson(Map<String, dynamic> json) => HistoryData(
        intro: json['intro'] as String?,
        sections: (json['sections'] as List<dynamic>)
            .map((e) => HistorySection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String? intro;
  final List<HistorySection> sections;
}
