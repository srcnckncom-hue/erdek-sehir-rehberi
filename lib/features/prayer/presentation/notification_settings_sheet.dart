import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/prayer_times.dart';
import '../notifications/prayer_notification_plan.dart';
import '../notifications/prayer_notifications.dart';

/// Bildirimi aç/kapat; açarken iOS izni istenir, verilmezse uyarı gösterilir.
Future<void> toggleNotifications(BuildContext context, WidgetRef ref, {required bool on}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final denied = AppLocalizations.of(context).notificationPermissionDenied;
  final ok = await ref.read(prayerNotificationSettingsProvider.notifier).setEnabled(on);
  if (!ok) messenger?.showSnackBar(SnackBar(content: Text(denied)));
}

Future<void> showNotificationSettingsSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.palette.background,
      builder: (_) => const _NotificationSettingsSheet(),
    );

class _NotificationSettingsSheet extends ConsumerWidget {
  const _NotificationSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final settings = ref.watch(prayerNotificationSettingsProvider);
    final notifier = ref.read(prayerNotificationSettingsProvider.notifier);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: l10n.notificationsTitle),
            const SizedBox(height: AppSpacing.md),
            GroupedCard(
              children: [
                SwitchListTile.adaptive(
                  value: settings.enabled,
                  onChanged: (on) => toggleNotifications(context, ref, on: on),
                  secondary: AppIcon(AppIcons.bellRinging, size: 26, color: p.iconOrange),
                  title: Text(
                    l10n.notificationsTitle,
                    style: AppTypography.label.copyWith(color: p.textHeading),
                  ),
                ),
              ],
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: settings.enabled ? 1 : 0.45,
              child: IgnorePointer(
                ignoring: !settings.enabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Padding(
                      padding: AppSpacing.pagePadding,
                      child: Text(
                        l10n.notificationWhenTitle,
                        style: AppTypography.label.copyWith(color: p.textHeading),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: AppSpacing.pagePadding,
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final m in PrayerNotificationSettings.minuteOptions)
                            ChoiceChip(
                              label: Text(
                                m == 0 ? l10n.notificationAtTime : l10n.notificationMinutesBefore(m),
                              ),
                              selected: settings.minutesBefore == m,
                              onSelected: (_) => notifier.setMinutesBefore(m),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Padding(
                      padding: AppSpacing.pagePadding,
                      child: Text(
                        l10n.notificationPrayersTitle,
                        style: AppTypography.label.copyWith(color: p.textHeading),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GroupedCard(
                      children: [
                        for (final prayer in PrayerName.values)
                          CheckboxListTile.adaptive(
                            value: settings.prayers.contains(prayer),
                            onChanged: (on) => notifier.togglePrayer(prayer, on: on ?? false),
                            title: Text(
                              l10n.prayerName(prayer.jsonKey),
                              style: AppTypography.label.copyWith(color: p.textBody),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: AppSpacing.pagePadding,
              child: Text(
                l10n.notificationHint,
                style: AppTypography.caption.copyWith(color: p.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
