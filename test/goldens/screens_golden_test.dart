@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:erdek_rehberi/app/launch/launch_splash.dart';
import 'package:erdek_rehberi/app/launch/onboarding_screen.dart';
import 'package:erdek_rehberi/app/shell/app_shell.dart';
import 'package:erdek_rehberi/features/explore/domain/explore.dart';
import 'package:erdek_rehberi/features/explore/presentation/history_screen.dart';
import 'package:erdek_rehberi/features/explore/presentation/place_detail_screen.dart';
import 'package:erdek_rehberi/features/explore/presentation/places_screen.dart';
import 'package:erdek_rehberi/features/settings/presentation/settings_screen.dart';

import '../helpers/test_overrides.dart';
import 'golden_helpers.dart';
import 'previews.dart';

/// Tasarım karşılaştırması için ekran görüntüleri.
/// CI: `flutter test --tags golden --update-goldens` → test/goldens/screens/*.png
/// → Actions'ta "screenshots" artifact'ı.
void main() {
  final firstPlace = PlacesData.fromJson(
    (jsonDecode(File('$fixturesDir/places.json').readAsStringSync())
        as Map<String, dynamic>)['data'] as Map<String, dynamic>,
  ).places.first;

  // Açılış animasyonu: çizim, gri dolgu, yazılar gelirken ve son kare.
  // Zemin her temada beyaz olduğu için yalnızca açık tema.
  for (final device in GoldenDevice.all) {
    for (final (name, value) in [('cizim', 0.22), ('gri', 0.47), ('yazilar', 0.76), ('son', 1.0)]) {
      testWidgets('açılış $name · ${device.name}', (tester) async {
        await takeScreenshot(
          tester,
          fileName: '11_acilis_${name}_${device.name}',
          device: device,
          brightness: Brightness.light,
          builder: () => Scaffold(
            body: LaunchSplash(onFinished: () {}, previewValue: value),
          ),
          precache: [for (final a in LaunchSplash.precacheAssets) AssetImage(a)],
        );
      });
    }
  }

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

      testWidgets('rehber · ${themeName(brightness)} · ${device.name}', (tester) async {
        await takeScreenshot(
          tester,
          fileName: '07_rehber_${themeName(brightness)}_${device.name}',
          device: device.withHeight(1500),
          brightness: brightness,
          builder: () => testScope(child: const AppShell(initialTab: AppTab.directory)),
        );
      });

      testWidgets('gezilecek yerler · ${themeName(brightness)} · ${device.name}', (tester) async {
        await takeScreenshot(
          tester,
          fileName: '08_gezilecek_yerler_${themeName(brightness)}_${device.name}',
          device: device.withHeight(1200),
          brightness: brightness,
          builder: () => testScope(child: const PlacesScreen()),
        );
      });

      testWidgets('yer ayrıntısı · ${themeName(brightness)} · ${device.name}', (tester) async {
        await takeScreenshot(
          tester,
          fileName: '09_yer_ayrinti_${themeName(brightness)}_${device.name}',
          device: device.withHeight(1300),
          brightness: brightness,
          builder: () => testScope(child: PlaceDetailScreen(place: firstPlace, isSample: true)),
        );
      });

      testWidgets('erdek tarihi · ${themeName(brightness)} · ${device.name}', (tester) async {
        await takeScreenshot(
          tester,
          fileName: '10_erdek_tarihi_${themeName(brightness)}_${device.name}',
          device: device.withHeight(1700),
          brightness: brightness,
          builder: () => testScope(child: const HistoryScreen()),
        );
      });

      for (var page = 0; page < OnboardingScreen.pageCount; page++) {
        testWidgets('tanıtım ${page + 1} · ${themeName(brightness)} · ${device.name}', (
          tester,
        ) async {
          await takeScreenshot(
            tester,
            fileName: '12_tanitim_${page + 1}_${themeName(brightness)}_${device.name}',
            device: device,
            brightness: brightness,
            builder: () => testScope(
              child: OnboardingScreen(initialPage: page, onFinished: () {}),
            ),
          );
        });
      }

      testWidgets('ayarlar · ${themeName(brightness)} · ${device.name}', (tester) async {
        await takeScreenshot(
          tester,
          fileName: '13_ayarlar_${themeName(brightness)}_${device.name}',
          device: device.withHeight(1500),
          brightness: brightness,
          builder: () => testScope(child: const SettingsScreen()),
        );
      });

      // Ana sayfanın tamamı (kaydırmadan, uzun ekran)
      testWidgets('ana sayfa tam boy · ${themeName(brightness)} · ${device.name}', (tester) async {
        await takeScreenshot(
          tester,
          fileName: '02_ana_sayfa_tam_boy_${themeName(brightness)}_${device.name}',
          device: device.withHeight(1800),
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
