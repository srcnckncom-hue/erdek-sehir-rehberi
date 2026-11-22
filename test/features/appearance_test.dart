import 'package:erdek_rehberi/features/appearance/appearance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ana sayfa arka planı: yalnızca https, her gün sıradaki', () {
    final data = AppearanceData.fromJson({
      'heroImages': [
        {'url': 'https://x/a.jpg'},
        {'url': 'http://guvensiz/b.jpg'},
        {'url': 'https://x/c.jpg', 'credit': 'Belediye'},
      ],
    });
    expect(data.heroImages, ['https://x/a.jpg', 'https://x/c.jpg']);
    expect(data.heroFor(DateTime(2026, 1, 1)), 'https://x/a.jpg');
    expect(data.heroFor(DateTime(2026, 1, 2)), 'https://x/c.jpg');
    expect(const AppearanceData().heroFor(DateTime(2026, 5, 5)), isNull);
  });
}
