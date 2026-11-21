import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/launch_or_notify.dart';
import '../../../core/util/launchers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../explore/presentation/place_photos.dart';
import '../../settings/presentation/report_issue.dart';
import '../domain/business.dart';
import 'business_style.dart';

Future<void> openBusiness(
  BuildContext context,
  Business business, {
  BusinessCategory? category,
  bool isSample = false,
}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BusinessDetailScreen(business: business, category: category, isSample: isSample),
      ),
    );

/// "+902661234567" → "https://wa.me/902661234567"
String whatsappUrl(String phone) => 'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}';

/// İşletme ayrıntısı: fotoğraflar, tanım, çalışma saatleri, iletişim düğmeleri.
class BusinessDetailScreen extends StatelessWidget {
  const BusinessDetailScreen({super.key, required this.business, this.category, this.isSample = false});

  final Business business;
  final BusinessCategory? category;
  final bool isSample;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final b = business;
    final icon = category?.icon ?? BusinessIcon.other;

    final actions = <Widget>[
      if (b.phone case final phone?)
        _ActionRow(
          key: const Key('business_call'),
          icon: AppIcons.call,
          color: p.mint.foreground,
          title: l10n.businessCall,
          value: Launchers.formatPhone(phone),
          onTap: () => launchOrNotify(context, () => Launchers.call(phone)),
        ),
      if (b.whatsapp case final phone?)
        _ActionRow(
          icon: AppIcons.whatsapp,
          color: p.mint.foreground,
          title: l10n.businessWhatsapp,
          value: Launchers.formatPhone(phone),
          onTap: () => launchOrNotify(context, () => Launchers.openUrl(whatsappUrl(phone))),
        ),
      if (b.website case final url?)
        _ActionRow(
          icon: AppIcons.globe,
          color: p.iconBlue,
          title: l10n.businessWebsite,
          value: _shortUrl(url),
          onTap: () => launchOrNotify(context, () => Launchers.openUrl(url)),
        ),
      if (b.instagram case final url?)
        _ActionRow(
          icon: AppIcons.instagram,
          color: p.iconCoral,
          title: l10n.socialInstagram,
          value: _shortUrl(url),
          onTap: () => launchOrNotify(context, () => Launchers.openUrl(url)),
        ),
      if (b.hasLocation)
        _ActionRow(
          icon: AppIcons.directions,
          color: p.primary,
          title: l10n.directions,
          value: b.address,
          onTap: () => launchOrNotify(
            context,
            () => Launchers.directions(
              name: b.name,
              address: b.address,
              latitude: b.latitude,
              longitude: b.longitude,
            ),
          ),
        ),
    ];

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          PageHeader(
            title: b.name,
            subtitle: category?.title,
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.back,
          ),
          if (isSample) ...[
            InfoBanner(icon: AppIcons.info, message: l10n.sampleDataBanner),
            const SizedBox(height: AppSpacing.md),
          ],
          _Gallery(business: b, icon: icon),
          if (b.summary != null || b.paragraphs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (b.summary case final summary?)
                    Text(summary, style: AppTypography.label.copyWith(color: p.textHeading)),
                  for (final paragraph in b.paragraphs) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      paragraph,
                      style: AppTypography.body.copyWith(color: p.textBody, height: 1.6),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (b.hours case final hours?) ...[
            const SizedBox(height: AppSpacing.xl),
            Container(
              margin: AppSpacing.pagePadding,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: AppRadius.cardAll,
                boxShadow: AppShadows.card(p.shadow),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(AppIcons.clock, size: 22, color: p.iconOrange),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.businessHours,
                          style: AppTypography.label.copyWith(
                            color: p.textHeading,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(hours, style: AppTypography.caption.copyWith(color: p.textBody)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.section),
            SectionHeader(title: l10n.businessContactTitle),
            const SizedBox(height: AppSpacing.md),
            GroupedCard(children: actions),
          ],
          const SizedBox(height: AppSpacing.lg),
          ReportIssueLink(section: '${l10n.businessesTitle}: ${b.name}'),
        ],
      ),
    );
  }

  /// "https://www.ornek.com/abc/" → "ornek.com/abc"
  static String _shortUrl(String url) {
    var s = url.replaceFirst(RegExp(r'^https://'), '').replaceFirst(RegExp(r'^www\.'), '');
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);
    return s;
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.value,
  });

  final AppIconData icon;
  final Color color;
  final String title;
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
              AppIcon(icon, size: 22, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTypography.label.copyWith(color: p.textHeading)),
                    if (value case final text?)
                      Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(color: p.textSecondary),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppIcon(AppIcons.caretRight, size: 18, color: p.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fotoğraflar (kaydırılabilir); yoksa kategori ikonu.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.business, required this.icon});

  final Business business;
  final BusinessIcon icon;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final photos = widget.business.photos;
    final fallback = BusinessIconTile(icon: widget.icon, iconSize: 56);

    if (photos.isEmpty) {
      return Padding(
        padding: AppSpacing.pagePadding,
        child: ClipRRect(
          borderRadius: AppRadius.cardAll,
          child: SizedBox(height: 140, child: fallback),
        ),
      );
    }

    final credit = photos[_page.clamp(0, photos.length - 1)].credit;
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.cardAll,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => PlacePhotoImage(
                      url: photos[i].url,
                      fallback: fallback,
                      semanticLabel: l10n.placePhotoLabel(widget.business.name),
                    ),
                  ),
                  if (photos.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: AppSpacing.md,
                      child: IgnorePointer(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < photos.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _page ? 18 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: i == _page ? 1 : 0.6),
                                  borderRadius: AppRadius.pillAll,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (credit != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.placePhotoCredit(credit),
              style: AppTypography.caption.copyWith(color: p.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
