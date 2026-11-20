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
}
