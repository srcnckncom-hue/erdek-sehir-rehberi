import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../share/share_actions.dart';
import '../domain/pharmacy.dart';

/// Eczane listesindeki kart: ad, adres, telefon + Ara / Yol tarifi.
class PharmacyCard extends StatelessWidget {
  const PharmacyCard({
    super.key,
    required this.pharmacy,
    required this.onCall,
    required this.onDirections,
    this.note,
    this.shareText,
  });

  final Pharmacy pharmacy;

  /// O güne özel not (Eczacı Odası listesinden), ör. "Gece 22:00'a kadar nöbetçidir."
  final String? note;
  final VoidCallback onCall;
  final VoidCallback onDirections;

  /// Verilirse yanında WhatsApp'ta paylaş düğmesi çıkar.
  final String? shareText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Container(
      margin: AppSpacing.pagePadding,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.cardAll,
        boxShadow: AppShadows.card(p.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: p.accentRed.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon(AppIcons.pill, size: 26, color: p.accentRed),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharmacy.name,
                      style: AppTypography.greeting.copyWith(
                        color: p.textHeading,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pharmacy.address,
                      style: AppTypography.caption.copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pharmacy.phone,
                      style: AppTypography.caption.copyWith(color: p.textBody),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (note case final text?) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              key: const Key('pharmacy_duty_note'),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(color: p.warning, borderRadius: AppRadius.tileAll),
              child: Row(
                children: [
                  AppIcon(AppIcons.dutyNote, size: 20, color: p.iconOrange),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTypography.tileLabel.copyWith(color: p.textHeading),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: AppIcons.call,
                  label: l10n.call,
                  background: p.accentRed,
                  foreground: Colors.white,
                  onTap: onCall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionButton(
                  icon: AppIcons.directions,
                  label: l10n.directions,
                  background: p.accentRed.withValues(alpha: 0.10),
                  foreground: p.accentRed,
                  onTap: onDirections,
                ),
              ),
              if (shareText case final text?) ...[
                const SizedBox(width: AppSpacing.sm),
                WhatsAppShareButton(key: const Key('pharmacy_share'), text: text),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final AppIconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: AppRadius.pillAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(icon, size: 18, color: foreground),
                const SizedBox(width: AppSpacing.xs),
                // Büyük yazı boyutunda (Dynamic Type) taşmasın.
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.label.copyWith(color: foreground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
