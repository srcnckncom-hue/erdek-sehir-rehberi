import 'dart:convert';

import 'package:erdek_rehberi/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Ekran görüntüsü alınan iPhone boyutları (mantıksal pt, ölçek, güvenli alan).
class GoldenDevice {
  const GoldenDevice({
    required this.name,
    required this.size,
    required this.pixelRatio,
    required this.safeTop,
    required this.safeBottom,
  });

  final String name;
  final Size size;
  final double pixelRatio;
  final double safeTop;
  final double safeBottom;

  /// iPhone SE (3. nesil) — en küçük desteklenen ekran.
  static const small = GoldenDevice(
    name: 'kucuk_iphone_se',
    size: Size(375, 667),
    pixelRatio: 2,
    safeTop: 20,
    safeBottom: 0,
  );

  /// iPhone 16 Pro Max — App Store 6.9" (1320×2868 px).
  static const large = GoldenDevice(
    name: 'buyuk_iphone_16_pro_max',
    size: Size(440, 956),
    pixelRatio: 3,
    safeTop: 62,
    safeBottom: 34,
  );

  static const all = [small, large];

  GoldenDevice withHeight(double height) => GoldenDevice(
        name: name,
        size: Size(size.width, height),
        pixelRatio: pixelRatio,
        safeTop: safeTop,
        safeBottom: safeBottom,
      );
}

bool _fontsLoaded = false;

/// Testler varsayılan olarak "Ahem" (kutu) fontu kullanır. Gerçek fontları
/// (Poppins, Phosphor ikonları, Material ikonları) FontManifest'ten yükler.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font in (family['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
  _fontsLoaded = true;
}

/// [builder] ile kurulan ekranı verilen cihaz ve temada çizip
/// test/goldens/screens/<dosya>.png olarak kaydeder.
Future<void> takeScreenshot(
  WidgetTester tester, {
  required String fileName,
  required GoldenDevice device,
  required Brightness brightness,
  required Widget Function() builder,
  List<ImageProvider> precache = const [],
}) async {
  await loadAppFonts();

  tester.view
    ..physicalSize = device.size * device.pixelRatio
    ..devicePixelRatio = device.pixelRatio
    ..padding = FakeViewPadding(
      top: device.safeTop * device.pixelRatio,
      bottom: device.safeBottom * device.pixelRatio,
    )
    ..viewPadding = FakeViewPadding(
      top: device.safeTop * device.pixelRatio,
      bottom: device.safeBottom * device.pixelRatio,
    );
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: builder(),
    ),
  );

  // Görsellerin gerçekten çözülmesi için gerçek zamanlı bekleme gerekir.
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    for (final image in precache) {
      await precacheImage(image, context);
    }
  });
  await tester.pumpAndSettle();

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('screens/$fileName.png'),
  );
}

String themeName(Brightness b) => b == Brightness.dark ? 'koyu' : 'acik';
