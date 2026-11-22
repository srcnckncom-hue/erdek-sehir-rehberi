import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/time/calendar_date.dart';
import '../../core/util/launch_or_notify.dart';
import '../../core/util/launchers.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'markets.dart';

Future<void> openMarkets(BuildContext context, {VoidCallback? onOpenAnnouncements}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MarketsScreen(onOpenAnnouncements: onOpenAnnouncements)),
    );

abstract final class MarketTexts {
  /// "08:00–14:00" · "08:00'den" · null
  static String? hours(Market m) => switch ((m.startTime, m.endTime)) {
        (final s?, final e?) => '$s–$e',
        (final s?, null) => '$s',
        _ => null,
      };

  /// "Haziran–Ağustos" (ardışık aylar) ya da "Haziran, Eylül".
  static String months(AppLocalizations l10n, Market m) {
    final ms = [...m.months]..sort();
    final consecutive = [for (var i = 1; i < ms.length; i++) ms[i] == ms[i - 1] + 1].every((x) => x);
    if (ms.length > 2 && consecutive) return '${l10n.monthName('${ms.first}')}–${l10n.monthName('${ms.last}')}';
    return [for (final x in ms) l10n.monthName('$x')].join(', ');
  }

  static String dayLabel(AppLocalizations l10n, int weekday, CalendarDate today) {
    final name = l10n.weekdayName('$weekday');
    if (weekday == today.weekday) return '${l10n.today} · $name';
    if (weekday == today.addDays(1).weekday) return '${l10n.tomorrow} · $name';
    return name;
  }
}

/// Semt pazarları: bugün kurulanlar + haftalık çizelge.
class MarketsScreen extends ConsumerWidget {
  const MarketsScreen({super.key, this.onOpenAnnouncements});

  final VoidCallback? onOpenAnnouncements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
    final today = CalendarDate.fromDateTime(now);
    final result = ref.watch(marketsDataProvider);
    final data = result.value?.data;
    final open = data?.todayOpen(now) ?? const <Market>[];
    final week = data?.byWeekday(today) ?? const <int, List<Market>>{};
    final days = [for (var i = 0; i < 7; i++) today.addDays(i).weekday].where(week.containsKey).toList();

    final children = <Widget>[
      PageHeader(
        title: l10n.marketsTitle,
        subtitle: l10n.marketsSubtitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.back,
      ),
      if (result.value?.isSample ?? false) ...[
        InfoBanner(icon: AppIcons.info, message: l10n.sampleDataBanner),
        const SizedBox(height: AppSpacing.md),
      ],
    ];

    if (data == null && !result.hasError) {
      children.add(const Padding(padding: AppSpacing.pagePadding, child: SkeletonBox(height: 120, radius: AppRadius.card)));
    } else if (week.isEmpty) {
      children.add(MessageView(
        key: const Key('markets_empty'),
        icon: AppIcons.market,
        iconColor: p.iconPurple,
        title: l10n.marketsEmptyTitle,
        message: l10n.marketsEmptyMessage,
      ));
    } else {
      children.add(Padding(
        padding: AppSpacing.pagePadding,
        child: Container(
          key: const Key('markets_today'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(color: p.iconPurple.withValues(alpha: 0.10), borderRadius: AppRadius.cardAll),
          child: Row(
            children: [
              AppIcon(AppIcons.market, size: 28, color: p.iconPurple),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  open.isEmpty
                      ? l10n.marketsNoneToday
                      : l10n.marketsToday(open.map((m) => m.name).join(', ')),
                  style: AppTypography.label.copyWith(color: p.textHeading),
                ),
              ),
            ],
          ),
        ),
      ));
      for (final wd in days) {
        children.addAll([
          const SizedBox(height: AppSpacing.section),
          SectionHeader(title: MarketTexts.dayLabel(l10n, wd, today)),
          const SizedBox(height: AppSpacing.md),
          GroupedCard(children: [for (final m in week[wd]!) _MarketRow(market: m)]),
        ]);
      }
    }

    if (onOpenAnnouncements case final openAnn?) {
      children.addAll([
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton.icon(
            key: const Key('markets_announcements'),
            onPressed: () {
              Navigator.of(context).pop();
              openAnn();
            },
            icon: AppIcon(AppIcons.announcements, size: 18, color: p.primary),
            label: Text(l10n.marketsAnnouncementsLink),
          ),
        ),
      ]);
    }

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: children,
      ),
    );
  }
}

class _MarketRow extends StatelessWidget {
  const _MarketRow({required this.market});

  final Market market;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final m = market;
    final lines = [
      ?MarketTexts.hours(m),
      ?m.place,
      if (m.isSeasonal) l10n.marketsSeasonal(MarketTexts.months(l10n, m)),
      ?m.note,
    ];
    return Padding(
      key: Key('market_${m.id}'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name, style: AppTypography.label.copyWith(color: p.textHeading)),
                for (final line in lines) Text(line, style: AppTypography.caption.copyWith(color: p.textSecondary)),
              ],
            ),
          ),
          if (m.hasLocation)
            IconButton(
              tooltip: l10n.directions,
              onPressed: () => unawaited(launchOrNotify(
                context,
                () => Launchers.directions(name: m.name, latitude: m.latitude, longitude: m.longitude),
              )),
              icon: AppIcon(AppIcons.directions, size: 20, color: p.primary),
            ),
        ],
      ),
    );
  }
}

/// Ana sayfa: "Bugün pazar var" (yoksa görünmez).
class HomeMarketBanner extends ConsumerWidget {
  const HomeMarketBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
    final open = ref.watch(marketsDataProvider).value?.data.todayOpen(now) ?? const <Market>[];
    if (open.isEmpty) return const SizedBox.shrink();
    final first = open.first;
    final detail = [?MarketTexts.hours(first), ?first.place].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.section),
      child: Material(
        color: p.iconPurple.withValues(alpha: 0.10),
        borderRadius: AppRadius.cardAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('home_market_banner'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                AppIcon(AppIcons.market, size: 26, color: p.iconPurple),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.marketsToday(open.map((m) => m.name).join(', ')),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(color: p.textHeading),
                      ),
                      if (detail.isNotEmpty)
                        Text(detail, style: AppTypography.caption.copyWith(color: p.textBody)),
                    ],
                  ),
                ),
                AppIcon(AppIcons.arrowRight, size: 18, color: p.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
