import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';

Future<void> openAtaturk(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AtaturkScreen()),
    );

/// Anma günleri (ana sayfadaki "Erdek'te bugün" kartında hatırlatılır).
abstract final class ErdekCommemorations {
  /// 24 Haziran: Atatürk'ün Erdek'e gelişi (1938).
  static bool isAtaturkDay(DateTime d) => d.month == 6 && d.day == 24;

  /// 18 Eylül: Erdek'in kurtuluşu (1922).
  static bool isLiberationDay(DateTime d) => d.month == 9 && d.day == 18;
}

/// Atatürk ve Erdek: 24 Haziran 1938 Savarona ziyareti ve Kurtuluş.
class AtaturkScreen extends StatelessWidget {
  const AtaturkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final crimson = p.accentRed;

    Widget fact(String label, String text) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.tabLabel.copyWith(color: crimson, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(text, style: AppTypography.body.copyWith(color: p.textBody)),
            ],
          ),
        );

    return Scaffold(
      body: ListView(
        key: const Key('ataturk_page'),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          PageHeader(
            title: l10n.ataturkTitle,
            subtitle: '24 Haziran 1938',
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.back,
          ),
          Padding(
            padding: AppSpacing.pagePadding,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: crimson.withValues(alpha: 0.08), borderRadius: AppRadius.cardAll),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(AppIcons.ataturk, size: 30, color: crimson),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Gazi Mustafa Kemal Atatürk, 24 Haziran 1938 Cuma günü Savarona yatıyla Erdek’e gelmiş, '
                      'sağlık durumu nedeniyle karaya çıkmadan yatın güvertesinden halkı selamlamıştır.',
                      style: AppTypography.body.copyWith(color: p.textHeading, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          const SectionHeader(title: 'Ziyaretin ayrıntıları'),
          const SizedBox(height: AppSpacing.md),
          GroupedCard(
            children: [
              fact(
                'TARİH VE SAAT',
                '24 Haziran 1938’de öğle saatlerinde İstanbul’dan ayrılan Savarona yatı, saat 18.00 civarında '
                    'Erdek’e ulaşmış ve saat 22.00’de hareket etmiştir.',
              ),
              fact('GÖRÜŞMELER', 'Atatürk, yatında Donanma Komutanı Şükrü Okan’ı kabul etmiştir.'),
              fact(
                'ÖNEMİ',
                'Bu ziyaret, Atatürk’ün resmî olarak gerçekleştirdiği son ilçe/şehir ziyaretlerinden biri olarak '
                    'bilinir ve Erdek’te her yıl 24 Haziran’da deniz korteji ve çeşitli törenlerle anılır.',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.section),
          const SectionHeader(title: 'Erdek ve Kurtuluş Mücadelesi'),
          const SizedBox(height: AppSpacing.md),
          GroupedCard(
            children: [
              fact('KURTULUŞ GÜNÜ', 'Erdek, 18 Eylül 1922’de düşman işgalinden kurtulmuştur.'),
              fact(
                'ATATÜRK ANITI',
                'İlçede heykeltıraş Rahmi Aksungur tarafından yapılan (1982) Atatürk Anıtı bulunur ve resmî '
                    'anma programları burada düzenlenir.',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: AppSpacing.pagePadding,
            child: Text(
              'Kaynak: Özel Erdek, Bandırma Manşet',
              style: AppTypography.tabLabel.copyWith(color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
