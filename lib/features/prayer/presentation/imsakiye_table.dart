import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/time/calendar_date.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/prayer_times.dart';

/// Aylık imsakiye tablosu. Bugünün satırı vurgulanır.
class ImsakiyeTable extends StatelessWidget {
  const ImsakiyeTable({super.key, required this.days, required this.today});

  final List<PrayerDay> days;
  final CalendarDate today;

  static const _dayFlex = 14;
  static const _timeFlex = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final headerStyle = AppTypography.tabLabel.copyWith(color: p.textSecondary, fontWeight: FontWeight.w600);

    Widget row(List<Widget> cells, {Color? background, bool rounded = false}) => Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: rounded ? BorderRadius.circular(AppRadius.sm) : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 1),
          child: Row(children: cells),
        );

    Widget cell(String text, TextStyle style, {int flex = _timeFlex, TextAlign align = TextAlign.center}) =>
        Expanded(
          flex: flex,
          child: Text(text, style: style, textAlign: align, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
        );

    return Container(
      margin: AppSpacing.pagePadding,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.tileAll,
        boxShadow: AppShadows.card(p.shadow),
      ),
      child: Column(
        children: [
          row([
            cell(l10n.dayColumn, headerStyle, flex: _dayFlex, align: TextAlign.start),
            for (final name in PrayerName.values) cell(l10n.prayerName(name.jsonKey), headerStyle),
          ]),
          Divider(color: p.divider, height: AppSpacing.xs),
          for (final day in days)
            Semantics(
              selected: day.date == today,
              child: row(
                [
                  cell(
                    '${day.date.day} ${l10n.weekdayShort('${day.date.weekday}')}',
                    _style(p, isToday: day.date == today, isDay: true),
                    flex: _dayFlex,
                    align: TextAlign.start,
                  ),
                  for (final name in PrayerName.values)
                    cell(day.timeOf(name).toString(), _style(p, isToday: day.date == today)),
                ],
                background: day.date == today ? p.primarySoft : null,
                rounded: true,
              ),
            ),
        ],
      ),
    );
  }

  TextStyle _style(AppPalette p, {required bool isToday, bool isDay = false}) =>
      AppTypography.tabLabel.copyWith(
        fontSize: 12,
        color: isToday ? p.primary : (isDay ? p.textSecondary : p.textBody),
        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
