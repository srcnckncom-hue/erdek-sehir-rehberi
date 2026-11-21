import 'package:material_ui/material_ui.dart';

import '../../../core/data/data_result.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/launch_or_notify.dart';
import '../../../core/util/launchers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/contacts.dart';

/// Rehber › Telefonlar: en üstte 112 kartı, altında kategorili liste.
class ContactsView extends StatelessWidget {
  const ContactsView({super.key, required this.result});

  final DataResult<ContactsData> result;

  /// 112 her zaman üstteki kırmızı kartta; listede tekrar edilmez.
  static const emergencyNumber = '112';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final children = <Widget>[
      Padding(
        padding: AppSpacing.pagePadding,
        child: FeatureCard(
          icon: AppIcons.emergency,
          overline: l10n.emergencyOverline,
          title: l10n.emergencyTitle,
          subtitle: l10n.emergencySubtitle,
          actions: [
            CardAction(
              icon: AppIcons.call,
              label: l10n.call,
              onTap: () => launchOrNotify(context, () => Launchers.call(emergencyNumber)),
            ),
          ],
        ),
      ),
    ];

    for (final category in result.data.categories) {
      final contacts = category.contacts.where((c) => c.phone != emergencyNumber).toList();
      if (contacts.isEmpty) continue;
      children.addAll([
        const SizedBox(height: AppSpacing.section),
        SectionHeader(title: category.title),
        const SizedBox(height: AppSpacing.md),
        GroupedCard(children: [for (final c in contacts) ContactRow(contact: c)]),
      ]);
    }

    children.addAll([
      const SizedBox(height: AppSpacing.lg),
      Padding(
        padding: AppSpacing.pagePadding,
        child: Text(
          l10n.contactsSourceNote,
          style: AppTypography.tabLabel.copyWith(color: p.textSecondary),
        ),
      ),
    ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class ContactRow extends StatelessWidget {
  const ContactRow({super.key, required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Semantics(
      button: true,
      label: l10n.callNamed(contact.name),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => launchOrNotify(context, () => Launchers.call(contact.phone)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: AppTypography.label.copyWith(color: p.textHeading),
                    ),
                    Text(
                      Launchers.formatPhone(contact.phone),
                      style: AppTypography.caption.copyWith(color: p.textBody),
                    ),
                    if (contact.note != null)
                      Text(
                        contact.note!,
                        style: AppTypography.tabLabel.copyWith(color: p.textSecondary),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                decoration: BoxDecoration(color: p.primarySoft, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: AppIcon(AppIcons.call, size: 20, color: p.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
