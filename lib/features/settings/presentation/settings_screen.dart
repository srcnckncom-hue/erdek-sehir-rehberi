import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_info.dart';
import '../../../app/providers.dart';
import '../../../core/system/system_bridge.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/launch_or_notify.dart';
import '../../../core/util/launchers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../prayer/notifications/prayer_notifications.dart';
import '../../prayer/presentation/notification_settings_sheet.dart';
import '../../push/push_service.dart';
import 'report_issue.dart';

Future<void> openSettings(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );

/// Ayarlar ve Hakkında: görünüm, bildirimler, destek (hata bildir, paylaş,
/// değerlendir), bağımsızlık notu, veri kaynakları, gizlilik / koşullar, sürüm.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const shareKey = Key('settings_share');
  static const reportKey = Key('settings_report');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final notificationsOn = ref.watch(prayerNotificationSettingsProvider.select((s) => s.enabled));
    final version = ref.watch(appVersionProvider).value;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          PageHeader(
            title: l10n.settingsTitle,
            subtitle: l10n.settingsSubtitle,
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.back,
          ),

          // Görünüm
          SectionHeader(title: l10n.appearanceTitle),
          const SizedBox(height: AppSpacing.md),
          SegmentedPills<ThemeMode>(
            key: const Key('settings_theme_mode'),
            selected: themeMode,
            onSelected: (mode) => ref.read(themeModeProvider.notifier).setMode(mode),
            options: [
              SegmentOption(value: ThemeMode.light, label: l10n.themeLight, icon: AppIcons.themeLight),
              SegmentOption(value: ThemeMode.dark, label: l10n.themeDark, icon: AppIcons.themeDark),
              SegmentOption(value: ThemeMode.system, label: l10n.themeSystem, icon: AppIcons.themeSystem),
            ],
          ),
          const SizedBox(height: AppSpacing.section),

          // Dil (varsayılan Türkçe)
          SectionHeader(title: l10n.languageTitle),
          const SizedBox(height: AppSpacing.md),
          SegmentedPills<String>(
            key: const Key('settings_language'),
            selected: locale.languageCode,
            onSelected: (code) => ref.read(localeProvider.notifier).setLocale(Locale(code)),
            options: [
              SegmentOption(value: 'tr', label: l10n.languageTurkish),
              SegmentOption(value: 'en', label: l10n.languageEnglish),
            ],
          ),
          const SizedBox(height: AppSpacing.section),

          // Bildirimler
          SectionHeader(title: l10n.settingsNotificationsTitle),
          const SizedBox(height: AppSpacing.md),
          GroupedCard(
            children: [
              _SettingsRow(
                icon: AppIcons.bellRinging,
                color: p.iconOrange,
                title: l10n.notificationsTitle,
                value: notificationsOn ? l10n.notificationsOn : l10n.notificationsOff,
                onTap: () => showNotificationSettingsSheet(context),
              ),
              if (ref.watch(pushAvailableProvider))
                SwitchListTile.adaptive(
                  key: const Key('settings_announcements_push'),
                  value: ref.watch(announcementsPushProvider),
                  onChanged: (on) => toggleAnnouncementsPush(context, ref, on: on),
                  secondary: AppIcon(AppIcons.announcements, size: 24, color: p.iconPurple),
                  title: Text(
                    l10n.announcementsPushTitle,
                    style: AppTypography.label.copyWith(color: p.textHeading),
                  ),
                  subtitle: Text(
                    l10n.announcementsPushSubtitle,
                    style: AppTypography.caption.copyWith(color: p.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.section),

          // Destek
          SectionHeader(title: l10n.settingsSupportTitle),
          const SizedBox(height: AppSpacing.md),
          GroupedCard(
            children: [
              _SettingsRow(
                key: reportKey,
                icon: AppIcons.report,
                color: p.iconRed,
                title: l10n.reportIssueTitle,
                subtitle: AppInfo.supportEmail,
                onTap: () => openReportEmail(context, ref, section: l10n.settingsTitle),
              ),
              _SettingsRow(
                key: shareKey,
                icon: AppIcons.share,
                color: p.iconBlue,
                title: l10n.shareAppTitle,
                onTap: () => unawaited(
                  ref.read(systemBridgeProvider).share(l10n.shareAppText(AppInfo.shareUrl)),
                ),
              ),
              if (AppInfo.hasStoreId)
                _SettingsRow(
                  icon: AppIcons.star,
                  color: p.iconOrange,
                  title: l10n.rateAppTitle,
                  onTap: () => launchOrNotify(context, () => Launchers.openUrl(AppInfo.reviewUrl)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.section),

          // Hakkında
          SectionHeader(title: l10n.aboutTitle),
          const SizedBox(height: AppSpacing.md),
          InfoBanner(icon: AppIcons.info, message: l10n.drawerIndependentNote),
          const SizedBox(height: AppSpacing.md),
          _TextCard(title: l10n.drawerDataSources, body: l10n.dataSourcesBody),
          const SizedBox(height: AppSpacing.md),
          GroupedCard(
            children: [
              _SettingsRow(
                icon: AppIcons.shield,
                color: p.mint.foreground,
                title: l10n.privacyPolicyTitle,
                onTap: () => launchOrNotify(context, () => Launchers.openUrl(AppInfo.privacyUrl)),
              ),
              _SettingsRow(
                icon: AppIcons.document,
                color: p.iconPurple,
                title: l10n.termsTitle,
                onTap: () => launchOrNotify(context, () => Launchers.openUrl(AppInfo.termsUrl)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              version == null ? l10n.appTitle : l10n.versionLabel(version),
              style: AppTypography.caption.copyWith(color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.value,
  });

  final AppIconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            children: [
              AppIcon(icon, size: 24, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTypography.label.copyWith(color: p.textHeading)),
                    if (subtitle case final text?)
                      Text(text, style: AppTypography.caption.copyWith(color: p.textSecondary)),
                  ],
                ),
              ),
              if (value case final text?) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(text, style: AppTypography.caption.copyWith(color: p.textSecondary)),
              ],
              const SizedBox(width: AppSpacing.xs),
              AppIcon(AppIcons.caretRight, size: 18, color: p.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: AppSpacing.pagePadding,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: p.surface, borderRadius: AppRadius.cardAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.label.copyWith(color: p.textHeading)),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: AppTypography.caption.copyWith(color: p.textBody)),
        ],
      ),
    );
  }
}

/// Duyuru bildirimlerini aç/kapat; izin verilmezse uyarı gösterir.
Future<void> toggleAnnouncementsPush(BuildContext context, WidgetRef ref, {required bool on}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final denied = AppLocalizations.of(context).notificationPermissionDenied;
  final ok = await ref.read(announcementsPushProvider.notifier).setEnabled(on);
  if (!ok) messenger?.showSnackBar(SnackBar(content: Text(denied)));
}
