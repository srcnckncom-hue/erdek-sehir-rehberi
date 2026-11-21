import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/data/data_result.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/launch_or_notify.dart';
import '../../core/util/launchers.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';

/// Uygulamanın sosyal medya hesapları (panel → Sosyal Medya).
/// Boş bırakılan hesap uygulamada gösterilmez.
class SocialLinks {
  const SocialLinks({this.instagram, this.facebook, this.x});

  factory SocialLinks.fromJson(Map<String, dynamic> json) => SocialLinks(
        instagram: _url(json['instagram']),
        facebook: _url(json['facebook']),
        x: _url(json['x']),
      );

  /// Yalnızca https:// adresleri kabul edilir.
  static String? _url(Object? value) {
    final text = (value as String?)?.trim();
    return text != null && text.startsWith('https://') ? text : null;
  }

  final String? instagram;
  final String? facebook;
  final String? x;

  bool get isEmpty => instagram == null && facebook == null && x == null;
}

final socialLinksProvider = StreamProvider<DataResult<SocialLinks>>(
  (ref) => ref.watch(offlineFirstLoaderProvider).watch('social.json', SocialLinks.fromJson),
);

/// Yuvarlak sosyal medya düğmeleri (Instagram, Facebook, X).
/// Hesap girilmemişse hiçbir şey çizmez.
class SocialLinksRow extends ConsumerWidget {
  const SocialLinksRow({super.key, this.alignment = MainAxisAlignment.start});

  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(socialLinksProvider).value?.data;
    if (links == null || links.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final p = context.palette;

    final items = <(Key, AppIconData, String, String)>[
      if (links.instagram case final url?)
        (const Key('social_instagram'), AppIcons.instagram, l10n.socialInstagram, url),
      if (links.facebook case final url?)
        (const Key('social_facebook'), AppIcons.facebook, l10n.socialFacebook, url),
      if (links.x case final url?) (const Key('social_x'), AppIcons.xLogo, l10n.socialX, url),
    ];

    return Row(
      mainAxisAlignment: alignment,
      children: [
        for (final (key, icon, label, url) in items)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Tooltip(
              message: label,
              child: Semantics(
                button: true,
                label: label,
                excludeSemantics: true,
                child: Material(
                  key: key,
                  color: p.surface,
                  shape: CircleBorder(side: BorderSide(color: p.divider)),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => launchOrNotify(context, () => Launchers.openUrl(url)),
                    child: SizedBox.square(
                      dimension: AppSpacing.minTouchTarget,
                      child: Center(child: AppIcon(icon, size: 22, color: p.textHeading)),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Ayarlar sayfası bölümü: "Bizi takip edin" + düğmeler. Hesap yoksa gizli.
class SocialFollowSection extends ConsumerWidget {
  const SocialFollowSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(socialLinksProvider).value?.data;
    if (links == null || links.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.socialTitle),
        const SizedBox(height: AppSpacing.md),
        const Padding(
          padding: AppSpacing.pagePadding,
          child: SocialLinksRow(),
        ),
        const SizedBox(height: AppSpacing.section),
      ],
    );
  }
}
