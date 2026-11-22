import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'push_service.dart';

Future<void> openPushTopics(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PushTopicsScreen()),
    );

/// Konuyu aç/kapat; izin verilmezse uyarı gösterir.
Future<void> togglePushTopic(BuildContext context, WidgetRef ref, PushTopic topic, {required bool on}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final denied = AppLocalizations.of(context).notificationPermissionDenied;
  final ok = await ref.read(pushTopicsProvider.notifier).setEnabled(topic, on);
  if (!ok) messenger?.showSnackBar(SnackBar(content: Text(denied)));
}

String pushTopicTitle(AppLocalizations l10n, PushTopic t) => switch (t) {
      PushTopic.general => l10n.announcementsPushTitle,
      PushTopic.outages => l10n.pushTopicOutages,
      PushTopic.transport => l10n.pushTopicTransport,
      PushTopic.events => l10n.pushTopicEvents,
    };

String pushTopicSubtitle(AppLocalizations l10n, PushTopic t) => switch (t) {
      PushTopic.general => l10n.pushTopicGeneralSubtitle,
      PushTopic.outages => l10n.pushTopicOutagesSubtitle,
      PushTopic.transport => l10n.pushTopicTransportSubtitle,
      PushTopic.events => l10n.pushTopicEventsSubtitle,
    };

/// Ayarlar › Bildirim konuları: her konu ayrı anahtar.
class PushTopicsScreen extends ConsumerWidget {
  const PushTopicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final on = ref.watch(pushTopicsProvider);

    (AppIconData, Color) style(PushTopic t) => switch (t) {
          PushTopic.general => (AppIcons.announcements, p.iconPurple),
          PushTopic.outages => (AppIcons.outage, p.iconCrimson),
          PushTopic.transport => (AppIcons.ferry, p.aqua.foreground),
          PushTopic.events => (AppIcons.event, p.iconOrange),
        };

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          PageHeader(
            title: l10n.pushTopicsTitle,
            subtitle: l10n.pushTopicsSubtitle,
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.back,
          ),
          GroupedCard(
            children: [
              for (final t in PushTopic.values)
                SwitchListTile.adaptive(
                  key: Key('push_topic_${t.topic}'),
                  value: on.contains(t),
                  onChanged: (v) => togglePushTopic(context, ref, t, on: v),
                  secondary: AppIcon(style(t).$1, size: 24, color: style(t).$2),
                  title: Text(pushTopicTitle(l10n, t), style: AppTypography.label.copyWith(color: p.textHeading)),
                  subtitle: Text(
                    pushTopicSubtitle(l10n, t),
                    style: AppTypography.caption.copyWith(color: p.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: AppSpacing.pagePadding,
            child: Text(
              l10n.pushTopicsNote,
              style: AppTypography.tabLabel.copyWith(color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
