import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/util/launch_or_notify.dart';
import '../../../core/util/launchers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/ads_repository.dart';
import '../domain/ad.dart';

/// Reklam alanı. Ekranda istediğin yere `AdSlot(id: 'home_feed_1')` koyman
/// yeterli. Slotta yayında reklam yoksa (ya da yüklenemezse) hiç yer kaplamaz.
/// Reklamlar admin panelinden yönetilir (Supabase).
class AdSlot extends ConsumerStatefulWidget {
  const AdSlot({super.key, required this.id, this.padding = EdgeInsets.zero, this.index = 0});

  /// Sabit slot kimliği (ör. home_feed_1, pharmacy_bottom).
  final String id;

  /// Reklam varsa etrafına uygulanacak boşluk (yoksa uygulanmaz).
  final EdgeInsets padding;

  /// Aynı slot bir sayfada birden çok kez kullanılıyorsa sıra numarası
  /// (sefer listesi arası); farklı reklamlar gösterilsin diye.
  final int index;

  @override
  ConsumerState<AdSlot> createState() => _AdSlotState();
}

class _AdSlotState extends ConsumerState<AdSlot> {
  String? _countedAdId;

  void _countImpression(Ad ad) {
    if (_countedAdId == ad.id) return;
    _countedAdId = ad.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(adsRepositoryProvider).record(ad, AdEventKind.impression));
    });
  }

  @override
  Widget build(BuildContext context) {
    final ads = ref.watch(activeAdsProvider).value ?? const <Ad>[];
    final ad = pickAd(
      ads,
      widget.id,
      now: DateTime.now(),
      rotation: ref.watch(adRotationSeedProvider) + widget.index,
    );
    if (ad == null) return const SizedBox.shrink();
    // Açılış animasyonu / tanıtım üstteyken sayma; perde kalkınca sayılır.
    if (!AdImpressionGate.isPaused(context)) _countImpression(ad);

    final repo = ref.read(adsRepositoryProvider);
    final link = ad.linkUrl;
    return Padding(
      padding: widget.padding,
      child: AdCard(
        image: NetworkImage(repo.imageUrl(ad)),
        title: ad.title,
        subtitle: ad.advertiser,
        adLabel: AppLocalizations.of(context).adLabel,
        onTap: link == null
            ? null
            : () {
                unawaited(repo.record(ad, AdEventKind.click));
                unawaited(launchOrNotify(context, () => Launchers.openUrl(link)));
              },
      ),
    );
  }
}

/// Altındaki reklam alanlarının gösterim sayımını durdurur. Açılış perdesi
/// (logo animasyonu, tanıtım) ana sayfanın üstündeyken kullanılır: reklam
/// kurulmuş ama kullanıcı onu henüz görmüyor. [paused] false olunca alanlar
/// yeniden çizilir ve gösterim o an sayılır.
class AdImpressionGate extends InheritedWidget {
  const AdImpressionGate({super.key, required this.paused, required super.child});

  final bool paused;

  static bool isPaused(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdImpressionGate>()?.paused ?? false;

  @override
  bool updateShouldNotify(AdImpressionGate oldWidget) => paused != oldWidget.paused;
}
