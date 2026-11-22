import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/system/system_bridge.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/launch_or_notify.dart';
import '../../core/util/launchers.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../contacts/data/contacts_repository.dart';
import '../contacts/presentation/contacts_view.dart';
import '../nearby/location_service.dart';
import '../share/share_actions.dart';
import 'emergency.dart';

Future<void> openEmergency(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const EmergencyScreen()),
    );

/// Acil durum: büyük 112 düğmesi, konumunu öğren/paylaş, ulusal hatlar,
/// rehberdeki yerel numaralar ve toplanma alanı. Ulusal kısım internetsiz çalışır.
class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final local = localEmergencyContacts(ref.watch(contactsDataProvider).value?.data);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          PageHeader(
            title: l10n.emergencyScreenTitle,
            subtitle: l10n.emergencyScreenSubtitle,
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.back,
          ),
          const Padding(padding: AppSpacing.pagePadding, child: _CallButton()),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: AppSpacing.pagePadding,
            child: Text(
              l10n.emergencyUnifiedNote,
              style: AppTypography.tabLabel.copyWith(color: p.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          SectionHeader(title: l10n.emergencyLocationTitle),
          const SizedBox(height: AppSpacing.md),
          const _LocationCard(),
          const SizedBox(height: AppSpacing.section),
          SectionHeader(title: l10n.emergencyHelpLinesTitle),
          const SizedBox(height: AppSpacing.md),
          GroupedCard(
            children: [for (final line in HelpLine.values) ContactRow(contact: line.toContact(l10n))],
          ),
          if (local.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.section),
            SectionHeader(title: l10n.emergencyLocalTitle),
            const SizedBox(height: AppSpacing.md),
            GroupedCard(children: [for (final c in local) ContactRow(contact: c)]),
          ],
          const SizedBox(height: AppSpacing.section),
          SectionHeader(title: l10n.emergencyDisasterTitle),
          const SizedBox(height: AppSpacing.md),
          GroupedCard(
            children: [
              ListTile(
                key: const Key('emergency_assembly'),
                leading: AppIcon(AppIcons.assembly, size: 24, color: p.iconOrange),
                title: Text(l10n.emergencyAssemblyTitle, style: AppTypography.label.copyWith(color: p.textHeading)),
                subtitle: Text(
                  l10n.emergencyAssemblySubtitle,
                  style: AppTypography.caption.copyWith(color: p.textSecondary),
                ),
                trailing: AppIcon(AppIcons.globe, size: 18, color: p.textSecondary),
                onTap: () => launchOrNotify(context, () => Launchers.openUrl(Emergency.assemblyAreaUrl)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kırmızı, büyük "112" düğmesi. iOS aramadan önce onay sorar.
class _CallButton extends StatelessWidget {
  const _CallButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    const onRed = Colors.white;
    return Semantics(
      button: true,
      label: l10n.callNamed(l10n.emergencyTitle),
      excludeSemantics: true,
      child: Material(
        color: p.accentRed,
        borderRadius: AppRadius.cardAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('emergency_112'),
          onTap: () => launchOrNotify(context, () => Launchers.call(Emergency.number)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: onRed.withValues(alpha: 0.18), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: AppIcon(AppIcons.call, size: 30, color: onRed),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Emergency.number,
                        style: AppTypography.display.copyWith(color: onRed, height: 1),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(l10n.emergencyCallLabel, style: AppTypography.label.copyWith(color: onRed)),
                      Text(
                        l10n.emergencyCallServices,
                        style: AppTypography.caption.copyWith(color: onRed.withValues(alpha: 0.9)),
                      ),
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

enum _LocState { idle, loading, ready, denied, unavailable }

/// "Konumumu bul": koordinatı büyük gösterir (112'ye okunur) ve
/// WhatsApp / paylaşım ile gönderir. Konum yalnızca kullanıcı isteyince alınır.
class _LocationCard extends ConsumerStatefulWidget {
  const _LocationCard();

  @override
  ConsumerState<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends ConsumerState<_LocationCard> {
  var _state = _LocState.idle;
  GeoPoint? _point;

  Future<void> _locate() async {
    setState(() => _state = _LocState.loading);
    try {
      final point = await ref.read(locationServiceProvider).current();
      if (!mounted) return;
      setState(() {
        _point = point;
        _state = _LocState.ready;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() => _state = e.failure == LocationFailure.denied ? _LocState.denied : _LocState.unavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final point = _point;

    final Widget body;
    switch (_state) {
      case _LocState.idle:
      case _LocState.loading:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.emergencyLocationHint, style: AppTypography.caption.copyWith(color: p.textBody)),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const Key('emergency_locate'),
              onPressed: _state == _LocState.loading ? null : _locate,
              icon: _state == _LocState.loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : AppIcon(AppIcons.myLocation, size: 20, color: p.onPrimary),
              label: Text(l10n.emergencyLocate),
            ),
          ],
        );
      case _LocState.denied:
      case _LocState.unavailable:
        final denied = _state == _LocState.denied;
        body = Column(
          key: const Key('emergency_location_error'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              denied ? l10n.nearbyDeniedTitle : l10n.nearbyUnavailableTitle,
              style: AppTypography.label.copyWith(color: p.textHeading),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              denied ? l10n.nearbyDeniedMessage : l10n.nearbyUnavailableMessage,
              style: AppTypography.caption.copyWith(color: p.textBody),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: _locate, child: Text(l10n.retry)),
          ],
        );
      case _LocState.ready:
        final coords = formatCoordinates(point!);
        final text = emergencyShareText(l10n, point);
        body = Column(
          key: const Key('emergency_location_ready'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.emergencyCoordinatesLabel, style: AppTypography.caption.copyWith(color: p.textSecondary)),
            const SizedBox(height: AppSpacing.xxs),
            Text(coords, style: AppTypography.cardTitle.copyWith(color: p.textHeading)),
            const SizedBox(height: AppSpacing.xxs),
            Text(l10n.emergencyReadToOperator, style: AppTypography.tabLabel.copyWith(color: p.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.icon(
                  key: const Key('emergency_share_whatsapp'),
                  onPressed: () => unawaited(shareToWhatsApp(ref, text)),
                  icon: AppIcon(AppIcons.whatsapp, size: 18, color: p.onPrimary),
                  label: Text(l10n.shareWhatsApp),
                ),
                OutlinedButton.icon(
                  key: const Key('emergency_share_other'),
                  onPressed: () => unawaited(ref.read(systemBridgeProvider).share(text)),
                  icon: AppIcon(AppIcons.share, size: 18, color: p.primary),
                  label: Text(l10n.shareOther),
                ),
                TextButton(
                  key: const Key('emergency_copy'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    await Clipboard.setData(ClipboardData(text: coords));
                    messenger?.showSnackBar(SnackBar(content: Text(l10n.copied)));
                  },
                  child: Text(l10n.copy),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: _locate, child: Text(l10n.emergencyRefresh)),
          ],
        );
    }

    return Container(
      key: const Key('emergency_location'),
      margin: AppSpacing.pagePadding,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: p.surface, borderRadius: AppRadius.cardAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          const SizedBox(height: AppSpacing.md),
          Text(l10n.emergencyLocationPrivacy, style: AppTypography.tabLabel.copyWith(color: p.textSecondary)),
        ],
      ),
    );
  }
}
