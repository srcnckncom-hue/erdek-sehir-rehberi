import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/erdek_time.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/weather_repository.dart';
import '../domain/weather.dart';

Future<void> openWeather(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WeatherScreen()),
    );

/// Hava durumu: şu an + günlük tahmin (MET Norway).
class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final result = ref.watch(currentWeatherProvider);
    final value = result.value;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();

    final children = <Widget>[
      PageHeader(
        title: l10n.weatherTitle,
        subtitle: value == null || value.data.daily.isEmpty
            ? l10n.locationLabel
            : l10n.weatherSubtitle(value.data.daily.length),
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.back,
      ),
    ];

    if (value == null) {
      children.add(
        result.hasError
            ? MessageView(
                icon: StateIcons.error,
                iconColor: p.accentRed,
                title: l10n.loadErrorTitle,
                message: l10n.loadErrorMessage,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(currentWeatherProvider),
              )
            : const SkeletonList(count: 6, itemHeight: 64),
      );
    } else {
      final w = value.data;
      if (value.isOffline) {
        children
          ..add(
            InfoBanner(
              icon: AppIcons.offline,
              message: l10n.offlineBanner(
                ErdekTime.hhmm(ErdekTime.toErdek(value.fetchedAt ?? value.updatedAt)),
              ),
            ),
          )
          ..add(const SizedBox(height: AppSpacing.md));
      }
      children
        ..add(_NowCard(weather: w))
        ..add(const SizedBox(height: AppSpacing.section));

      if (w.daily.isNotEmpty) {
        final low = w.daily.map((d) => d.minTemperatureC).reduce((a, b) => a < b ? a : b);
        final high = w.daily.map((d) => d.maxTemperatureC).reduce((a, b) => a > b ? a : b);
        final today = DateTime.utc(now.year, now.month, now.day);
        children
          ..add(SectionHeader(title: l10n.weatherDailyTitle))
          ..add(const SizedBox(height: AppSpacing.md))
          ..add(
            GroupedCard(
              children: [
                for (final day in w.daily)
                  _DayRow(
                    day: day,
                    label: _dayLabel(l10n, day, today),
                    low: low,
                    high: high,
                  ),
              ],
            ),
          );
      }
    }

    children
      ..add(const SizedBox(height: AppSpacing.xl))
      ..add(
        Padding(
          padding: AppSpacing.pagePadding,
          child: Text(
            l10n.weatherAttribution,
            textAlign: TextAlign.center,
            style: AppTypography.tabLabel.copyWith(color: p.textSecondary),
          ),
        ),
      );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentWeatherProvider);
          try {
            await ref.read(currentWeatherProvider.future);
          } catch (_) {
            // Hata ekranda gösterilir.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
          children: children,
        ),
      ),
    );
  }

  /// "Bugün", "Yarın", "Pazartesi 23.11"
  static String _dayLabel(AppLocalizations l10n, DailyForecast day, DateTime today) {
    final diff = DateTime.utc(day.year, day.month, day.day).difference(today).inDays;
    if (diff == 0) return l10n.weatherToday;
    if (diff == 1) return l10n.weatherTomorrow;
    final date = '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}';
    return '${l10n.weekdayName('${day.weekday}')} $date';
  }
}

class _NowCard extends StatelessWidget {
  const _NowCard({required this.weather});

  final CurrentWeather weather;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final w = weather;
    final details = <(AppIconData, String)>[
      if (w.relativeHumidity case final h?) (AppIcons.humidity, l10n.humidityLabel(h.round())),
      if (w.windSpeedKmh case final kmh?) (AppIcons.wind, l10n.windLabel(kmh)),
      if (w.minTemperatureC != null && w.maxTemperatureC != null)
        (
          AppIcons.thermometer,
          l10n.temperatureRange(w.minTemperatureC!.round(), w.maxTemperatureC!.round()),
        ),
    ];

    return Container(
      margin: AppSpacing.pagePadding,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: p.aqua.background,
        borderRadius: AppRadius.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.weatherNow, style: AppTypography.caption.copyWith(color: p.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                '${w.roundedTemperature}°',
                style: AppTypography.display.copyWith(color: p.textHeading),
              ),
              const SizedBox(width: AppSpacing.md),
              AppIcon(AppIcons.weather(w.symbolCode), size: 44, color: p.aqua.foreground),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.weatherCondition(weatherConditionKey(w.symbolCode)),
                  style: AppTypography.label.copyWith(color: p.textHeading),
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                for (final (icon, text) in details)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(icon, size: 18, color: p.textSecondary),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(text, style: AppTypography.caption.copyWith(color: p.textBody)),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Gün satırı: gün adı · simge · yağış · en düşük ━━━ en yüksek.
class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.label, required this.low, required this.high});

  final DailyForecast day;
  final String label;

  /// Tüm günlerin en düşük / en yüksek sıcaklığı (çubuk ölçeği).
  final double low;
  final double high;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final condition = l10n.weatherCondition(weatherConditionKey(day.symbolCode));
    final span = (high - low).abs() < 0.1 ? 1.0 : high - low;
    final start = ((day.minTemperatureC - low) / span).clamp(0.0, 1.0);
    final end = ((day.maxTemperatureC - low) / span).clamp(0.0, 1.0);
    final caption = AppTypography.caption.copyWith(color: p.textSecondary);

    return Semantics(
      label: '$label, $condition, ${day.minTemperatureC.round()}° – ${day.maxTemperatureC.round()}°',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: 104,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(color: p.textHeading, fontSize: 14),
                  ),
                  Text(
                    condition,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            AppIcon(AppIcons.weather(day.symbolCode), size: 26, color: p.aqua.foreground),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 44,
              child: day.hasPrecipitation
                  ? Text(
                      l10n.weatherPrecipitation(day.precipitationMm.toStringAsFixed(1)),
                      style: caption.copyWith(color: p.iconBlue, fontSize: 11),
                    )
                  : null,
            ),
            SizedBox(
              width: 30,
              child: Text(
                '${day.minTemperatureC.round()}°',
                textAlign: TextAlign.right,
                style: caption,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: p.divider,
                              borderRadius: AppRadius.pillAll,
                            ),
                          ),
                        ),
                        Positioned(
                          left: width * start,
                          width: width < 6 ? width : (width * (end - start)).clamp(6.0, width),
                          top: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [p.iconBlue, p.iconOrange]),
                              borderRadius: AppRadius.pillAll,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 30,
              child: Text(
                '${day.maxTemperatureC.round()}°',
                style: AppTypography.caption.copyWith(color: p.textHeading, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
