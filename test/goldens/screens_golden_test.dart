@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'golden_helpers.dart';
import 'previews.dart';

/// Tasarım karşılaştırması için ekran görüntüleri.
/// CI: `flutter test --tags golden --update-goldens` → test/goldens/screens/*.png
/// → Actions'ta "screenshots" artifact'ı.
void main() {
  for (final brightness in Brightness.values) {
    for (final device in GoldenDevice.all) {
      testWidgets('ana sayfa · ${themeName(brightness)} · ${device.name}', (tester) async {
        await takeScreenshot(
          tester,
          fileName: '01_ana_sayfa_${themeName(brightness)}_${device.name}',
          device: device,
          brightness: brightness,
          builder: () => const HomePreview(),
          precache: const [heroImage],
        );
      });

      // Ana sayfanın tamamı (kaydırmadan, uzun ekran)
      testWidgets('ana sayfa tam boy · ${themeName(brightness)} · ${device.name}', (tester) async {
        await takeScreenshot(
          tester,
          fileName: '02_ana_sayfa_tam_boy_${themeName(brightness)}_${device.name}',
          device: device.withHeight(1500),
          brightness: brightness,
          builder: () => const HomePreview(),
          precache: const [heroImage],
        );
      });
    }

    testWidgets('bileşen kataloğu · ${themeName(brightness)}', (tester) async {
      await takeScreenshot(
        tester,
        fileName: '03_bilesenler_${themeName(brightness)}',
        device: GoldenDevice.large.withHeight(1900),
        brightness: brightness,
        builder: () => const ComponentGallery(),
        precache: const [heroImage],
      );
    });
  }
}
