import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../announcements/domain/announcement.dart';

enum DirectorySegment { contacts, announcements }

/// Rehber sekmesinde seçili bölüm ve duyuru kategorisi. Ana sayfadaki
/// kısayollar (zil, Kesintiler, Pazar Günleri…) sekmeyi doğru yerde açar.
@immutable
class DirectorySelection {
  const DirectorySelection({this.segment = DirectorySegment.contacts, this.category});

  final DirectorySegment segment;

  /// null = tüm kategoriler
  final AnnouncementCategory? category;
}

final directorySelectionProvider =
    NotifierProvider<DirectorySelectionNotifier, DirectorySelection>(
  DirectorySelectionNotifier.new,
);

class DirectorySelectionNotifier extends Notifier<DirectorySelection> {
  @override
  DirectorySelection build() => const DirectorySelection();

  void showContacts() =>
      state = DirectorySelection(category: state.category);

  void showAnnouncements([AnnouncementCategory? category]) =>
      state = DirectorySelection(segment: DirectorySegment.announcements, category: category);

  void selectSegment(DirectorySegment segment) {
    state = DirectorySelection(segment: segment, category: state.category);
  }

  void selectCategory(AnnouncementCategory? category) =>
      state = DirectorySelection(segment: state.segment, category: category);
}
