import 'package:material_ui/material_ui.dart';

import '../../../core/data/data_result.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/erdek_time.dart';
import '../../../core/util/date_texts.dart';
import '../../../core/util/launch_or_notify.dart';
import '../../../core/util/launchers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/announcement.dart';

/// Rehber › Duyurular: kategori filtresi + süresi dolmamış duyurular.
class AnnouncementsView extends StatelessWidget {
  const AnnouncementsView({
    super.key,
    required this.result,
    required this.now,
    required this.category,
    required this.onCategory,
    required this.seenBefore,
  });

  final DataResult<AnnouncementsData> result;
  final DateTime now;
  final AnnouncementCategory? category;
  final ValueChanged<AnnouncementCategory?> onCategory;

  /// Bu ziyaretten önceki "son görülme"; daha yeni duyurular "Yeni" etiketli.
  final DateTime? seenBefore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = result.data
        .activeAt(now)
        .where((a) => category == null || a.category == category)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PillChoiceRow(
          items: [
            PillChoice(label: l10n.filterAll, selected: category == null, onTap: () => onCategory(null)),
            for (final c in AnnouncementCategory.values)
              PillChoice(
                label: l10n.categoryName(c.jsonValue),
                selected: category == c,
                onTap: () => onCategory(c),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          MessageView(
            icon: AppIcons.announcements,
            title: l10n.noAnnouncementsTitle,
            message: l10n.noAnnouncementsMessage,
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.gap),
            AnnouncementCard(
              announcement: items[i],
              isNew: seenBefore == null || items[i].publishedAt.isAfter(seenBefore!),
            ),
          ],
      ],
    );
  }
}

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.announcement, required this.isNew});

  final Announcement announcement;
  final bool isNew;

  static AppIconData iconFor(AnnouncementCategory c) => switch (c) {
        AnnouncementCategory.outage => AppIcons.outage,
        AnnouncementCategory.market => AppIcons.market,
        AnnouncementCategory.event => AppIcons.event,
        AnnouncementCategory.general => AppIcons.announcements,
      };

  static Color colorFor(AppPalette p, AnnouncementCategory c) => switch (c) {
        AnnouncementCategory.outage => p.iconCrimson,
        AnnouncementCategory.market => p.iconPurple,
        AnnouncementCategory.event => p.iconOrange,
        AnnouncementCategory.general => p.iconBlue,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final a = announcement;
    final color = colorFor(p, a.category);

    String fmt(DateTime instant) {
      final e = ErdekTime.toErdek(instant);
      return l10n.dateTimeShort(DateTexts.dayMonth(l10n, CalendarDate.fromDateTime(e)), ErdekTime.hhmm(e));
    }

    final when = switch ((a.startsAt, a.endsAt)) {
      (final DateTime s, final DateTime e) => l10n.dateRange(fmt(s), fmt(e)),
      (final DateTime s, null) => fmt(s),
      _ => fmt(a.publishedAt),
    };

    return Container(
      margin: AppSpacing.pagePadding,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.tileAll,
        boxShadow: AppShadows.card(p.shadow),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AppIcon(iconFor(a.category), size: 24, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.categoryName(a.category.jsonValue),
                        style: AppTypography.tabLabel.copyWith(color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(color: p.badge, borderRadius: AppRadius.pillAll),
                        child: Text(
                          l10n.newBadge,
                          style: AppTypography.tabLabel.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  a.title,
                  style: AppTypography.label.copyWith(color: p.textHeading, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(a.body, style: AppTypography.caption.copyWith(color: p.textBody)),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    AppIcon(AppIcons.clock, size: 16, color: p.textSecondary),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: Text(when, style: AppTypography.tabLabel.copyWith(color: p.textSecondary)),
                    ),
                  ],
                ),
                if (a.link != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => launchOrNotify(context, () => Launchers.openUrl(a.link!)),
                      child: Text(l10n.openDetails),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
