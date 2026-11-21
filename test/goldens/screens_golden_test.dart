@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:erdek_rehberi/app/shell/app_shell.dart';

import '../helpers/test_overrides.dart';
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
          builder: () => testScope(child: const AppShell()),
          precache: const [heroImage],
        );
      });

      testWidgets('eczane · ${themeName(brightness)} · ${device.name}', (tester) async {
        await takeScreenshot(
          tester,
          fileName: '04_eczane_${themeName(brightness)}_${device.name}',
          device: device.withHeight(1300),
          brightness: brightness,
          builder: () => testScope(child: const AppShell(initialTab: AppTab.pharmacy)),
        );
      });

      testWidgets('vakitler · ${themeName(brightness)} · ${device.name}', (tester) async {
        await takeScreenshot(
          tester,
          fileName: '05_vakitler_${themeName(brightness)}_${device.name}',
          device: device.withHeight(2300),
          brightness: brightness,
          builder: () => testScope(child: const AppShell(initialTab: AppTab.prayer)),
        );
      });

      testWidgets('ulaşım · ${themeName(brightness)} · ${device.name}', (tester) async {
        await takeScreenshot(
          tester,
          fileName: '06_ulasim_${themeName(brightness)}_${device.name}',
          device: device.withHeight(1400),
          brightness: brightness,
          builder: () => testScope(child: const AppShell(initialTab: AppTab.transport)),
        );
      });

      // Ana sayfanın tamamı (kaydırmadan, uzun ekran)
      testWidgets('ana sayfa tam boy · ${themeName(brightness)} · ${device.name}', (tester) async {
        await takeScreenshot(
          tester,
          fileName: '02_ana_sayfa_tam_boy_${themeName(brightness)}_${device.name}',
          device: device.withHeight(1500),
          brightness: brightness,
          builder: () => testScope(child: const AppShell()),
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
