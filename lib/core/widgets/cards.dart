import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Kart altındaki hap buton ("Ara", "Yol tarifi").
class CardAction {
  const CardAction({required this.icon, required this.label, this.onTap});

  final AppIconData icon;
  final String label;
  final VoidCallback? onTap;
}

/// Büyük renkli kart (görselde kırmızı "Hizmet Eczanesi" kartı).
/// Bizde: bugünün nöbetçi eczanesi.
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.overline,
    required this.title,
    this.subtitle,
    this.tagLabel,
    this.tagIcon,
    this.actions = const [],
    this.footnote,
    this.color,
    this.onTap,
  });

  final AppIconData icon;
  final String overline;
  final String title;
  final String? subtitle;

  /// Sağ üstteki hap etiket (görselde "Bildirimler").
  final String? tagLabel;
  final AppIconData? tagIcon;
  final List<CardAction> actions;

  /// Kartın en altındaki küçük not ("Gitmeden önce telefonla teyit edin.").
  final String? footnote;

  /// Varsayılan: vurgu kırmızısı.
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = color ?? p.accentRed;
    final darker = Color.lerp(base, Colors.black, 0.18)!;
    const onCard = Colors.white;

    return ClipRRect(
      borderRadius: AppRadius.cardAll,
      child: Material(
        color: base,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [base, darker],
              ),
            ),
            child: Stack(
              children: [
                // Dekoratif büyük ikon (görseldeki silüet yerine)
                Positioned(
                  right: -18,
                  bottom: -22,
                  child: AppIcon(icon, size: 140, color: onCard.withValues(alpha: 0.10)),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: onCard.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: AppIcon(icon, size: 26, color: onCard),
                          ),
                          const Spacer(),
                          if (tagLabel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: onCard.withValues(alpha: 0.18),
                                borderRadius: AppRadius.pillAll,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (tagIcon != null) ...[
                                    AppIcon(tagIcon!, size: 16, color: onCard),
                                    const SizedBox(width: AppSpacing.xs),
                                  ],
                                  Text(
                                    tagLabel!,
                                    style: AppTypography.tileLabel.copyWith(color: onCard),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        overline,
                        style: AppTypography.caption.copyWith(
                          color: onCard.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: AppTypography.cardTitle.copyWith(color: onCard),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTypography.caption.copyWith(
                            color: onCard.withValues(alpha: 0.9),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final a in actions)
                              _PillButton(action: a, background: onCard, foreground: base),
                          ],
                        ),
                      ],
                      if (footnote != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          footnote!,
                          style: AppTypography.tabLabel.copyWith(
                            color: onCard.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
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

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.action,
    required this.background,
    required this.foreground,
  });

  final CardAction action;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: AppRadius.pillAll,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: AppRadius.pillAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(action.icon, size: 18, color: foreground),
                const SizedBox(width: AppSpacing.xs),
                Text(action.label, style: AppTypography.tileLabel.copyWith(color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Küçük beyaz bilgi kartı (görselde "Nöbetçi Eczaneler · Bugün · 12:15").
/// Bizde: sıradaki namaz vakti.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.label,
    required this.value,
    this.footnote,
    this.onTap,
  });

  final String title;
  final AppIconData icon;
  final String label;
  final String value;
  final String? footnote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.cardAll,
        boxShadow: AppShadows.card(p.shadow),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(color: p.textSecondary),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p.primary, width: 2.5),
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(icon, size: 26, color: p.primary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(label, style: AppTypography.caption.copyWith(color: p.textSecondary)),
                Text(value, style: AppTypography.value.copyWith(color: p.textBody)),
                if (footnote != null)
                  Text(
                    footnote!,
                    style: AppTypography.tabLabel.copyWith(color: p.primary),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
