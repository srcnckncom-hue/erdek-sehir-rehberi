import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../reminders/reminder_scheduler.dart';
import 'domain/search_index.dart';

/// Son aramalar (cihazda, en fazla 8). Hiçbir yere gönderilmez.
final recentSearchesProvider = NotifierProvider<RecentSearchesNotifier, List<String>>(RecentSearchesNotifier.new);

class RecentSearchesNotifier extends Notifier<List<String>> {
  static const storeKey = 'search_recent';

  @override
  List<String> build() {
    final raw = ref.watch(reminderStoreProvider).read(storeKey);
    if (raw == null) return const [];
    try {
      return [for (final v in jsonDecode(raw) as List<dynamic>) v as String];
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(String query) async {
    final next = pushRecent(state, query);
    if (identical(next, state)) return;
    state = next;
    await ref.read(reminderStoreProvider).write(storeKey, jsonEncode(next));
  }

  Future<void> clear() async {
    state = const [];
    await ref.read(reminderStoreProvider).write(storeKey, null);
  }
}
