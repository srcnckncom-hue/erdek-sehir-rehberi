/// Verinin nereden geldiği.
enum DataOrigin {
  /// Az önce internetten indirildi.
  network,

  /// Daha önce indirilip cihazda saklanan kopya.
  cache,

  /// Uygulamayla birlikte gelen kopya (ilk açılış, hiç internet yoksa).
  bundled,
}

/// Ekrana verilecek veri + durumu.
class DataResult<T> {
  const DataResult({
    required this.data,
    required this.origin,
    required this.isSample,
    required this.updatedAt,
    this.fetchedAt,
    this.refreshError,
  });

  final T data;
  final DataOrigin origin;

  /// JSON'da `isSample: true` ise "ÖRNEK VERİ" uyarısı gösterilecek.
  final bool isSample;

  /// Verinin kaynağında son güncellenme zamanı.
  final DateTime updatedAt;

  /// Cihaza en son ne zaman indirildi ("son güncelleme: ...").
  final DateTime? fetchedAt;

  /// Yenileme denendi ama başarısız olduysa hata (çevrimdışı vb.).
  final Object? refreshError;

  bool get isOffline => refreshError != null;

  DataResult<T> withRefreshError(Object error) => DataResult<T>(
        data: data,
        origin: origin,
        isSample: isSample,
        updatedAt: updatedAt,
        fetchedAt: fetchedAt,
        refreshError: error,
      );
}
