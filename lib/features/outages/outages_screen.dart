import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/time/calendar_date.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../home/presentation/home_texts.dart';
import '../share/share_actions.dart';
import 'outages.dart';

Future<void> openOutages(BuildContext context, {VoidCallback? onOpenAnnouncements}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => OutagesScreen(onOpenAnnouncements: onOpenAnnouncements)),
    );

abstract final class OutageStyle {
  static AppIconData icon(OutageType t) => switch (t) {
        OutageType.water => AppIcons.water,
        OutageType.electricity => AppIcons.outage,
        OutageType.gas => AppIcons.flame,
        OutageType.road => AppIcons.road,
        OutageType.other => AppIcons.warning,
      };

  static Color color(AppPalette p, OutageType t) => switch (t) {
        OutageType.water => p.iconBlue,
        OutageType.electricity => p.iconOrange,
        OutageType.gas => p.iconCrimson,
        OutageType.road => p.iconPurple,
        OutageType.other => p.iconCoral,
      };

  /// "Su kesintisi", "Elektrik kesintisi"…
  static String title(AppLocalizations l10n, OutageType t) => switch (t) {
        OutageType.water => l10n.outageWater,
        OutageType.electricity => l10n.outageElectricity,
        OutageType.gas => l10n.outageGas,
        OutageType.road => l10n.outageRoad,
        OutageType.other => l10n.outageOther,
      };

  static String areas(AppLocalizations l10n, Outage o) => o.isCitywide ? l10n.outageCitywide : o.areas.join(', ');

  static String _two(int v) => v.toString().padLeft(2, '0');
  static String _hm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  /// "Bugün 09:00 – 15:00" · "Yarın 22:00 – 25.11 06:00" · "Bugün 10:30 – giderilene kadar"
  static String when(AppLocalizations l10n, Outage o, DateTime now) {
    final today = CalendarDate.fromDateTime(now);
    final startDay = CalendarDate.fromDateTime(o.startsAt);
    final start = '${HomeTexts.relativeDay(l10n, startDay, today)} ${_hm(o.startsAt)}';
    final end = o.endsAt;
    if (end == null) return '$start – ${l10n.outageUntilFixed}';
    final endDay = CalendarDate.fromDateTime(end);
    return endDay == startDay
        ? '$start – ${_hm(end)}'
        : '$start – ${HomeTexts.relativeDay(l10n, endDay, today)} ${_hm(end)}';
  }

  static String shareText(AppLocalizations l10n, Outage o, DateTime now) => [
        '⚠ ${title(l10n, o.type)}',
        areas(l10n, o),
        when(l10n, o, now),
        ?o.reason,
        if (o.source case final s?) l10n.outageSource(s),
        '— ${l10n.appTitle}',
      ].join('\n');
}

/// Mahalle seçimi (alt pencere).
Future<void> pickMyArea(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final areas = ref.read(outagesDataProvider).value?.data.allAreas() ?? const <String>[];
  final current = ref.read(myAreaProvider);
  final picked = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: l10n.outageMyAreaPick),
          const SizedBox(height: AppSpacing.sm),
          if (areas.isEmpty)
            Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text(l10n.outageNoAreas))
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final a in areas)
                    ListTile(
                      key: Key('area_$a'),
                      title: Text(a),
                      trailing: current != null && normalizeArea(current) == normalizeArea(a)
                          ? AppIcon(AppIcons.check, size: 20, color: sheetContext.palette.primary)
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(a),
                    ),
                  if (current != null)
                    ListTile(
                      key: const Key('area_clear'),
                      title: Text(l10n.outageMyAreaClear, style: TextStyle(color: sheetContext.palette.accentRed)),
                      onTap: () => Navigator.of(sheetContext).pop(''),
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
  if (picked == null) return;
  await ref.read(myAreaProvider.notifier).set(picked.isEmpty ? null : picked);
}

/// Kesintiler: Mahallem seçimi, hatırlatma, süren ve planlı kesintiler.
class OutagesScreen extends ConsumerWidget {
  const OutagesScreen({super.key, this.onOpenAnnouncements});

  final VoidCallback? onOpenAnnouncements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
    final result = ref.watch(outagesDataProvider);
    final data = result.value?.data;
    final myArea = ref.watch(myAreaProvider);
    final remindOn = ref.watch(outageRemindersProvider);
    final current = data?.current(now) ?? const <Outage>[];
    final active = [for (final o in current) if (o.isActiveAt(now)) o];
    final planned = [for (final o in current) if (!o.isActiveAt(now)) o];

    List<Widget> section(String title, List<Outage> list) => [
          const SizedBox(height: AppSpacing.section),
          SectionHeader(title: title),
          const SizedBox(height: AppSpacing.md),
          for (final o in list) ...[
            OutageCard(outage: o, now: now, myArea: myArea),
            const SizedBox(height: AppSpacing.sm),
          ],
        ];

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          PageHeader(
            title: l10n.outagesTitle,
            subtitle: l10n.outagesSubtitle,
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.back,
          ),
          if (result.value?.isSample ?? false) ...[
            InfoBanner(icon: AppIcons.info, message: l10n.sampleDataBanner),
            const SizedBox(height: AppSpacing.md),
          ],
          GroupedCard(
            children: [
              ListTile(
                key: const Key('outage_my_area'),
                leading: AppIcon(AppIcons.mapPin, size: 24, color: p.primary),
                title: Text(l10n.outageMyArea, style: AppTypography.label.copyWith(color: p.textHeading)),
                subtitle: Text(
                  myArea ?? l10n.outageMyAreaNone,
                  style: AppTypography.caption.copyWith(color: p.textSecondary),
                ),
                trailing: AppIcon(AppIcons.arrowRight, size: 18, color: p.textSecondary),
                onTap: () => unawaited(pickMyArea(context, ref)),
              ),
              if (myArea != null)
                SwitchListTile.adaptive(
                  key: const Key('outage_remind'),
                  value: remindOn,
                  onChanged: (on) async {
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    final ok = await ref.read(outageRemindersProvider.notifier).setEnabled(on);
                    if (!ok) {
                      messenger?.showSnackBar(SnackBar(content: Text(l10n.notificationPermissionDenied)));
                    }
                  },
                  secondary: AppIcon(AppIcons.bellRinging, size: 24, color: p.iconOrange),
                  title: Text(l10n.outageRemind, style: AppTypography.label.copyWith(color: p.textHeading)),
                  subtitle: Text(
                    l10n.outageRemindSubtitle,
                    style: AppTypography.caption.copyWith(color: p.textSecondary),
                  ),
                ),
            ],
          ),
          if (data == null && !result.hasError)
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.section, AppSpacing.page, 0),
              child: SkeletonBox(height: 110, radius: AppRadius.card),
            )
          else if (current.isEmpty)
            MessageView(
              key: const Key('outages_empty'),
              icon: AppIcons.check,
              iconColor: p.mint.foreground,
              title: l10n.outagesEmptyTitle,
              message: l10n.outagesEmptyMessage,
            )
          else ...[
            if (active.isNotEmpty) ...section(l10n.outagesActive, active),
            if (planned.isNotEmpty) ...section(l10n.outagesPlanned, planned),
          ],
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: AppSpacing.pagePadding,
            child: Text(l10n.outagesSourceNote, style: AppTypography.tabLabel.copyWith(color: p.textSecondary)),
          ),
          if (onOpenAnnouncements case final open?)
            Center(
              child: TextButton.icon(
                key: const Key('outages_announcements'),
                onPressed: () {
                  Navigator.of(context).pop();
                  open();
                },
                icon: AppIcon(AppIcons.announcements, size: 18, color: p.primary),
                label: Text(l10n.outagesAnnouncementsLink),
              ),
            ),
        ],
      ),
    );
  }
}

class OutageCard extends ConsumerWidget {
  const OutageCard({super.key, required this.outage, required this.now, this.myArea});

  final Outage outage;
  final DateTime now;
  final String? myArea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final o = outage;
    final color = OutageStyle.color(p, o.type);
    final mine = o.affects(myArea);
    final active = o.isActiveAt(now);

    Widget tag(String text, Color c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
          decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: AppRadius.pillAll),
          child: Text(text, style: AppTypography.tabLabel.copyWith(color: c, fontWeight: FontWeight.w600)),
        );

    return Container(
      key: Key('outage_${o.id}'),
      margin: AppSpacing.pagePadding,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.cardAll,
        border: mine ? Border.all(color: color, width: 1.5) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AppIcon(OutageStyle.icon(o.type), size: 24, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(OutageStyle.title(l10n, o.type), style: AppTypography.label.copyWith(color: p.textHeading)),
                    if (active) tag(l10n.outageNow, p.accentRed),
                    if (mine) tag(l10n.outageMine, color),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(OutageStyle.areas(l10n, o), style: AppTypography.caption.copyWith(color: p.textBody)),
                Text(
                  OutageStyle.when(l10n, o, now),
                  style: AppTypography.caption.copyWith(color: p.textHeading, fontWeight: FontWeight.w600),
                ),
                if (o.reason case final r?)
                  Text(r, style: AppTypography.caption.copyWith(color: p.textSecondary)),
                if (o.note case final n?)
                  Text(n, style: AppTypography.caption.copyWith(color: p.textSecondary)),
                if (o.source case final s?) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(l10n.outageSource(s), style: AppTypography.tabLabel.copyWith(color: p.textSecondary)),
                ],
              ],
            ),
          ),
          WhatsAppShareButton(text: OutageStyle.shareText(l10n, o, now), size: 36),
        ],
      ),
    );
  }
}

/// Ana sayfa: süren ya da 24 saat içinde başlayacak kesinti (mahallem öncelikli).
class HomeOutageBanner extends ConsumerWidget {
  const HomeOutageBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
    final myArea = ref.watch(myAreaProvider);
    final o = ref.watch(outagesDataProvider).value?.data.headline(now, myArea);
    if (o == null) return const SizedBox.shrink();
    final color = OutageStyle.color(p, o.type);
    final active = o.isActiveAt(now);
    final title = active
        ? l10n.outageBannerNow(OutageStyle.title(l10n, o.type))
        : l10n.outageBannerSoon(OutageStyle.title(l10n, o.type));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Material(
          color: color.withValues(alpha: 0.10),
          borderRadius: AppRadius.cardAll,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const Key('home_outage_banner'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  AppIcon(OutageStyle.icon(o.type), size: 26, color: color),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTypography.label.copyWith(color: p.textHeading)),
                        Text(
                          '${o.affects(myArea) && !o.isCitywide ? myArea! : OutageStyle.areas(l10n, o)} · '
                          '${OutageStyle.when(l10n, o, now)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(color: p.textBody),
                        ),
                      ],
                    ),
                  ),
                  AppIcon(AppIcons.arrowRight, size: 18, color: p.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
