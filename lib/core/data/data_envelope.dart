/// data/*.json dosyalarının ortak zarfı:
///
/// ```json
/// {
///   "schemaVersion": 1,
///   "isSample": true,
///   "updatedAt": "2026-11-21T00:00:00+03:00",
///   "source": "Elle derlendi",
///   "data": { ... }
/// }
/// ```
class DataEnvelope<T> {
  const DataEnvelope({
    required this.schemaVersion,
    required this.isSample,
    required this.updatedAt,
    required this.data,
    this.source,
  });

  factory DataEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> data) parseData,
  ) {
    return DataEnvelope<T>(
      schemaVersion: json['schemaVersion'] as int,
      isSample: json['isSample'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      source: json['source'] as String?,
      data: parseData(json['data'] as Map<String, dynamic>),
    );
  }

  /// Uygulamanın anlayabildiği en yüksek şema sürümü.
  static const supportedSchemaVersion = 1;

  final int schemaVersion;
  final bool isSample;
  final DateTime updatedAt;
  final String? source;
  final T data;
}
