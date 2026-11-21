import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_info.dart';
import '../../../core/system/system_bridge.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/launch_or_notify.dart';
import '../../../core/util/launchers.dart';
import '../../../l10n/app_localizations.dart';

/// Hata bildirimi e-postasını açar: konu "[bölüm]", metinde sürüm.
Future<void> openReportEmail(BuildContext context, WidgetRef ref, {required String section}) async {
  final l10n = AppLocalizations.of(context);
  final version = ref.read(appVersionProvider).value ?? '-';
  await launchOrNotify(
    context,
    () => Launchers.email(
      to: AppInfo.supportEmail,
      subject: l10n.reportSubject(section),
      body: l10n.reportBody(version),
    ),
  );
}

/// Sayfa altlarındaki "Bu bilgi yanlış mı? Bildirin" bağlantısı.
class ReportIssueLink extends ConsumerWidget {
  const ReportIssueLink({super.key, required this.section});

  /// E-posta konusunda görünen bölüm adı ("Nöbetçi Eczane" gibi).
  final String section;

  static const linkKey = Key('report_issue_link');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: linkKey,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            foregroundColor: p.primary,
          ),
          onPressed: () => openReportEmail(context, ref, section: section),
          icon: AppIcon(AppIcons.report, size: 18, color: p.primary),
          label: Text(
            l10n.reportIssueLink,
            style: AppTypography.caption.copyWith(color: p.primary, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
