import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/util/date_texts.dart';
import '../../../l10n/app_localizations.dart';
import '../../beaches/swim_score.dart';
import '../../events/events.dart';
import '../../explore/presentation/ataturk_screen.dart';
import '../../events/events_screen.dart';
import '../../markets/markets.dart';
import '../../markets/markets_screen.dart';
import '../../outages/outages.dart';
import '../../outages/outages_screen.dart';
import '../../pharmacy/data/pharmacy_repository.dart';
import '../../pharmacy/domain/duty_schedule.dart';
import '../../weather/data/weather_repository.dart';
import '../../weather/domain/weather.dart';

/// "Erdek'te bugün": hava, deniz, nöbetçi eczane, pazar, etkinlik, kesinti tek kartta.
/// Her satır ilgili sayfayı açar; verisi olmayan satır görünmez.
class TodayCard extends ConsumerWidget {
  const TodayCard({
    super.key,
    required this.onWeather,
    required this.onSea,
    required this.onPharmacy,
    required this.onMarkets,
    required this.onEvents,
    required this.onOutages,
    this.onAtaturk,
  });

  final VoidCallback onWeather;
  final VoidCallback onSea;
  final VoidCallback onPharmacy;
  final VoidCallback onMarkets;
  final VoidCallback onEvents;
  final VoidCallback onOutages;

  /// 24 Haziran / 18 Eylül anma satırı (Atatürk ve Erdek sayfası).
  final VoidCallback? onAtaturk;

  /// Deniz satırı yalnızca mayıs–ekim.
  static bool swimSeason(DateTime now) => now.month >= 5 && now.month <= 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
    final today = CalendarDate.fromDateTime(now);

    final rows = <Widget>[];
    void row(Key key, AppIconData icon, Color color, String label, String text, VoidCallback onTap, {bool alert = false}) {
      rows.add(_TodayRow(
        key: key,
        icon: icon,
        color: color,
        label: label,
        text: text,
        alert: alert,
        onTap: onTap,
      ));
    }

    if (onAtaturk case final open?) {
      final text = ErdekCommemorations.isAtaturkDay(now)
          ? l10n.todayAtaturkDay
          : ErdekCommemorations.isLiberationDay(now)
              ? l10n.todayLiberationDay
              : null;
      if (text != null) row(const Key('today_commemoration'), AppIcons.ataturk, p.accentRed, l10n.todayCommemoration, text, open);
    }

    final outage = ref.watch(outagesDataProvider).value?.data.headline(now, ref.watch(myAreaProvider));
    if (outage != null) {
      final title = OutageStyle.title(l10n, outage.type);
      row(
        const Key('today_outage'),
        OutageStyle.icon(outage.type),
        OutageStyle.color(p, outage.type),
        outage.isActiveAt(now) ? l10n.outageBannerNow(title) : l10n.outageBannerSoon(title),
        '${OutageStyle.areas(l10n, outage)} · ${OutageStyle.when(l10n, outage, now)}',
        onOutages,
        alert: true,
      );
    }

    final w = ref.watch(currentWeatherProvider).value?.data;
    if (w != null) {
      row(
        const Key('today_weather'),
        AppIcons.forecast,
        p.iconBlue,
        l10n.todayWeather,
        [
          '${w.temperatureC.round()}°',
          l10n.weatherCondition(weatherConditionKey(w.symbolCode)),
          if (w.windSpeedMs case final ws?) l10n.swimFactorWind('${ws.round()}'),
        ].join(' · '),
        onWeather,
      );
    }

    final swim = swimSeason(now) ? ref.watch(todaySwimScoreProvider) : null;
    if (swim != null) {
      final verdict = switch (swim.level) {
        SwimLevel.great => l10n.swimGreat,
        SwimLevel.good => l10n.swimGood,
        SwimLevel.fair => l10n.swimFair,
        SwimLevel.poor => l10n.swimPoor,
      };
      row(const Key('today_sea'), AppIcons.placeBeach, p.aqua.foreground, l10n.todaySea, '$verdict (${swim.score})', onSea);
    }

    final duty = ref.watch(pharmacyDataProvider).value?.data.onDutyFor(dutyDateFor(now)) ?? const [];
    if (duty.isNotEmpty) {
      row(
        const Key('today_pharmacy'),
        AppIcons.pharmacy,
        p.accentRed,
        l10n.todayPharmacy,
        duty.map((d) => d.name).join(', '),
        onPharmacy,
      );
    }

    final markets = ref.watch(marketsDataProvider).value?.data.todayOpen(now) ?? const <Market>[];
    if (markets.isNotEmpty) {
      final m = markets.first;
      row(
        const Key('today_market'),
        AppIcons.market,
        p.iconPurple,
        l10n.todayMarket,
        [m.name, ?MarketTexts.hours(m), if (markets.length > 1) '+${markets.length - 1}'].join(' · '),
        onMarkets,
      );
    }

    final events = [
      for (final e in ref.watch(upcomingEventsProvider))
        if (e.listDay(today) == today) e,
    ];
    if (events.isNotEmpty) {
      final e = events.first;
      row(
        const Key('today_event'),
        EventStyle.icon(e.category),
        EventStyle.color(p, e.category),
        l10n.todayEvent,
        [e.title, EventStyle.when(l10n, e), if (events.length > 1) '+${events.length - 1}'].join(' · '),
        onEvents,
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.section),
      child: Container(
        key: const Key('today_card'),
        decoration: BoxDecoration(color: p.surface, borderRadius: AppRadius.cardAll),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: l10n.todayTitle, style: AppTypography.label.copyWith(color: p.textHeading)),
                    TextSpan(
                      text: '  ${DateTexts.weekdayDayMonth(l10n, today)}',
                      style: AppTypography.caption.copyWith(color: p.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            ...rows,
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.text,
    required this.onTap,
    this.alert = false,
  });

  final AppIconData icon;
  final Color color;
  final String label;
  final String text;
  final VoidCallback onTap;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: alert ? color.withValues(alpha: 0.10) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: AppIcon(icon, size: 18, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.tabLabel.copyWith(color: p.textSecondary)),
                    Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: p.textHeading,
                        fontWeight: alert ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AppIcon(AppIcons.arrowRight, size: 16, color: p.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
