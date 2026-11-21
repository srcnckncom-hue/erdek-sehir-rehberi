import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_result.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/erdek_time.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../ads/presentation/ad_slot.dart';
import '../../announcements/data/announcements_repository.dart';
import '../../announcements/data/announcements_seen.dart';
import '../../announcements/presentation/announcements_view.dart';
import '../data/contacts_repository.dart';
import 'contacts_view.dart';
import 'directory_selection.dart';

/// Rehber sekmesi: Telefonlar / Duyurular.
/// Görselde karşılığı yok; ana sayfa stiline göre.
class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key, this.isActive = true});

  /// Sekme şu an ekranda mı? (IndexedStack tüm sekmeleri önceden kurar;
  /// duyurular yalnızca gerçekten görüldüğünde "okundu" sayılır.)
  final bool isActive;

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  bool _markedThisVisit = false;
  DateTime? _seenBefore;

  void _maybeMarkSeen(DirectorySelection selection) {
    final visible = widget.isActive && selection.segment == DirectorySegment.announcements;
    if (!visible) {
      _markedThisVisit = false;
      return;
    }
    if (_markedThisVisit) return;
    _markedThisVisit = true;
    _seenBefore = ref.read(announcementsLastSeenProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(announcementsLastSeenProvider.notifier).markSeen(ref.read(clockProvider)()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
    final selection = ref.watch(directorySelectionProvider);
    final notifier = ref.read(directorySelectionProvider.notifier);
    _maybeMarkSeen(selection);

    final isContacts = selection.segment == DirectorySegment.contacts;
    final contacts = ref.watch(contactsDataProvider);
    final announcements = ref.watch(announcementsProvider);

    final children = <Widget>[
      PageHeader(title: l10n.directoryScreenTitle, subtitle: l10n.directorySubtitle),
      SegmentedPills<DirectorySegment>(
        selected: selection.segment,
        onSelected: notifier.selectSegment,
        options: [
          SegmentOption(value: DirectorySegment.contacts, label: l10n.segmentContacts, icon: AppIcons.contacts),
          SegmentOption(
            value: DirectorySegment.announcements,
            label: l10n.segmentAnnouncements,
            icon: AppIcons.announcements,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
    ];

    Widget loadingOrError(AsyncValue<Object?> value, VoidCallback retry) => value.hasError
        ? MessageView(
            icon: StateIcons.error,
            iconColor: p.accentRed,
            title: l10n.loadErrorTitle,
            message: l10n.loadErrorMessage,
            actionLabel: l10n.retry,
            onAction: retry,
          )
        : const SkeletonList(count: 4, itemHeight: 64);

    if (isContacts) {
      final value = contacts.value;
      if (value == null) {
        children.add(loadingOrError(contacts, () => ref.invalidate(contactsDataProvider)));
      } else {
        children
          ..addAll(_banners(l10n, value))
          ..add(ContactsView(result: value));
      }
    } else {
      final value = announcements.value;
      if (value == null) {
        children.add(loadingOrError(announcements, () => ref.invalidate(announcementsProvider)));
      } else {
        children
          ..addAll(_banners(l10n, value))
          ..add(
            AnnouncementsView(
              result: value,
              now: now,
              category: selection.category,
              onCategory: notifier.selectCategory,
              seenBefore: _seenBefore,
            ),
          );
      }
    }

    children.add(
      const AdSlot(
        id: 'contacts_bottom',
        padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.section, AppSpacing.page, 0),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(contactsDataProvider)
          ..invalidate(announcementsProvider);
        try {
          if (isContacts) {
            await ref.read(contactsDataProvider.future);
          } else {
            await ref.read(announcementsProvider.future);
          }
        } catch (_) {
          // Hata ekranda gösterilir.
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg),
        children: children,
      ),
    );
  }

  List<Widget> _banners(AppLocalizations l10n, DataResult<Object> value) => [
        if (value.isSample) ...[
          InfoBanner(icon: AppIcons.info, message: l10n.sampleDataBanner),
          const SizedBox(height: AppSpacing.md),
        ],
        if (value.isOffline) ...[
          InfoBanner(
            icon: AppIcons.offline,
            message: l10n.offlineBanner(
              ErdekTime.hhmm(ErdekTime.toErdek(value.fetchedAt ?? value.updatedAt)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ];
}
