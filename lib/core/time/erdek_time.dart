import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// "Şu an" bilgisini veren fonksiyon. Testlerde sabit bir zamanla değiştirilir.
typedef Clock = DateTime Function();

/// Erdek (Europe/Istanbul) saati.
///
/// Domain fonksiyonları bu saatin yıl/ay/gün/saat/dakika ALANLARINI kullanır;
/// cihaz başka bir saat dilimindeyse bile eczane ve vakit hesapları doğru kalır.
abstract final class ErdekTime {
  static tz.Location? _location;

  static tz.Location get location {
    final location = _location;
    if (location == null) {
      throw StateError('ErdekTime.init() main() içinde çağrılmalı.');
    }
    return location;
  }

  static void init() {
    if (_location != null) return;
    tzdata.initializeTimeZones();
    _location = tz.getLocation('Europe/Istanbul');
  }

  static DateTime now() => tz.TZDateTime.now(location);

  static bool get isInitialized => _location != null;

  /// Bir anı (ör. indirme zamanı) Erdek saatine çevirir. init() yapılmamışsa
  /// (testler) cihaz saatini kullanır.
  static DateTime toErdek(DateTime instant) =>
      isInitialized ? tz.TZDateTime.from(instant, location) : instant.toLocal();

  /// "HH:mm" (alanlardan; saat dilimi dönüşümü yapmaz).
  static String hhmm(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
