import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/shell/app_tab.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/launch_or_notify.dart';
import '../../../core/util/launchers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../announcements/data/announcements_repository.dart';
import '../../announcements/presentation/announcements_view.dart';
import '../../contacts/data/contacts_repository.dart';
import '../../contacts/presentation/directory_selection.dart';
import '../../pharmacy/data/pharmacy_repository.dart';
import '../../transport/data/transport_repository.dart';
import '../../transport/presentation/transport_screen.dart' show modeIcon;
import '../../transport/presentation/transport_selection.dart';
import '../domain/search_index.dart';

Future<void> openSearch(BuildContext context, ValueChanged<AppTab> onOpenTab) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SearchScreen(onOpenTab: onOpenTab)),
    );

/// Eczane, telefon, sefer ve duyurularda cihaz içi arama.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, required this.onOpenTab});

  final ValueChanged<AppTab> onOpenTab;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Ekranı kapatıp ilgili sekmeye geçer.
  void _go(AppTab tab, [void Function()? prepare]) {
    prepare?.call();
    Navigator.of(context).pop();
    widget.onOpenTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final now = ref.watch(clockProvider)();

    final results = searchAll(
      query: _query,
      now: now,
      pharmacy: ref.watch(pharmacyDataProvider).value?.data,
      contacts: ref.watch(contactsDataProvider).value?.data,
      transport: ref.watch(transportDataProvider).value?.data,
      announcements: ref.watch(announcementsProvider).value?.data,
    );

    Widget section(String title, List<Widget> rows) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: title),
            const SizedBox(height: AppSpacing.sm),
            GroupedCard(children: rows),
          ],
        );

    final body = <Widget>[];
    if (_query.trim().length < 2) {
      body.add(MessageView(icon: AppIcons.info, title: l10n.searchEmptyPrompt));
    } else if (results.isEmpty) {
      body.add(MessageView(icon: AppIcons.info, title: l10n.searchNoResults(_query.trim())));
    } else {
      if (results.pharmacies.isNotEmpty) {
        body.add(section(l10n.searchSectionPharmacies, [
          for (final ph in results.pharmacies)
            _ResultRow(
              icon: AppIcons.pharmacy,
              color: p.accentRed,
              title: ph.name,
              subtitle: ph.address,
              onTap: () => _go(AppTab.pharmacy),
            ),
        ]));
      }
      if (results.contacts.isNotEmpty) {
        body.add(section(l10n.searchSectionContacts, [
          for (final c in results.contacts)
            _ResultRow(
              icon: AppIcons.contacts,
              color: p.iconBlue,
              title: c.name,
              subtitle: Launchers.formatPhone(c.phone),
              onTap: () => launchOrNotify(context, () => Launchers.call(c.phone)),
            ),
        ]));
      }
      if (results.routes.isNotEmpty) {
        body.add(section(l10n.searchSectionRoutes, [
          for (final r in results.routes)
            _ResultRow(
              icon: modeIcon(r.mode),
              color: p.aqua.foreground,
              title: r.title,
              subtitle: r.operatorName,
              onTap: () => _go(AppTab.transport, () {
                ref.read(transportSelectionProvider.notifier)
                  ..selectMode(r.mode)
                  ..selectRoute(r.id);
              }),
            ),
        ]));
      }
      if (results.announcements.isNotEmpty) {
        body.add(section(l10n.searchSectionAnnouncements, [
          for (final a in results.announcements)
            _ResultRow(
              icon: AnnouncementCard.iconFor(a.category),
              color: AnnouncementCard.colorFor(p, a.category),
              title: a.title,
              subtitle: l10n.categoryName(a.category.jsonValue),
              onTap: () => _go(
                AppTab.directory,
                () => ref.read(directorySelectionProvider.notifier).showAnnouncements(a.category),
              ),
            ),
        ]));
      }
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.xs, AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: AppRadius.pillAll,
                        boxShadow: AppShadows.raised(p.shadow),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: (v) => setState(() => _query = v),
                        style: AppTypography.body.copyWith(color: p.textBody),
                        decoration: InputDecoration(
                          hintText: l10n.searchHint,
                          hintStyle: AppTypography.body.copyWith(color: p.textSecondary),
                          border: InputBorder.none,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
                            child: AppIcon(AppIcons.search, size: 22, color: p.textSecondary),
                          ),
                          prefixIconConstraints: const BoxConstraints(minHeight: AppSpacing.searchHeight),
                          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg),
                children: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final AppIconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            AppIcon(icon, size: 24, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.label.copyWith(color: p.textHeading)),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTypography.caption.copyWith(color: p.textSecondary)),
                ],
              ),
            ),
            AppIcon(AppIcons.arrowRight, size: 18, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}
