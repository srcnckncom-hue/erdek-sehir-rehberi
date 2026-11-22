import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/data_result.dart';
import '../reminders/reminder_scheduler.dart';

/// Hikâyedeki bir sayfa (fotoğraf + isteğe bağlı yazı ve bağlantı).
class StorySlide {
  const StorySlide({required this.url, this.caption, this.link, this.linkLabel});

  factory StorySlide.fromJson(Map<String, dynamic> json) => StorySlide(
        url: json['url'] as String,
        caption: _text(json['caption']),
        link: _https(json['link']),
        linkLabel: _text(json['linkLabel']),
      );

  final String url;
  final String? caption;

  /// Yalnızca https:// (uygulama dışında açılır).
  final String? link;
  final String? linkLabel;
}

/// Ana sayfadaki yuvarlak hikâye (Instagram hikâyesi gibi).
class Story {
  const Story({
    required this.id,
    required this.title,
    required this.cover,
    required this.slides,
    this.startsAt,
    this.endsAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        id: json['id'] as String,
        title: json['title'] as String,
        cover: json['cover'] as String,
        slides: [
          for (final s in json['slides'] as List<dynamic>? ?? const [])
            StorySlide.fromJson(s as Map<String, dynamic>),
        ],
        startsAt: _date(json['startsAt']),
        endsAt: _date(json['endsAt']),
      );

  final String id;
  final String title;

  /// Yuvarlak kapak fotoğrafı.
  final String cover;
  final List<StorySlide> slides;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool isActiveAt(DateTime now) =>
      slides.isNotEmpty &&
      (startsAt == null || !now.isBefore(startsAt!)) &&
      (endsAt == null || now.isBefore(endsAt!));

  /// İçerik değişince (sayfa eklenince) yeniden "yeni" sayılsın.
  String get seenKey => '$id:${slides.length}';
}

class StoriesData {
  const StoriesData({required this.stories});

  factory StoriesData.fromJson(Map<String, dynamic> json) => StoriesData(
        stories: [
          for (final s in json['stories'] as List<dynamic>? ?? const [])
            Story.fromJson(s as Map<String, dynamic>),
        ],
      );

  final List<Story> stories;

  /// Yayında olanlar (panel sırasıyla).
  List<Story> activeAt(DateTime now) => [for (final s in stories) if (s.isActiveAt(now)) s];
}

String? _text(Object? v) {
  final t = (v as String?)?.trim();
  return t == null || t.isEmpty ? null : t;
}

String? _https(Object? v) {
  final t = _text(v);
  return t != null && t.startsWith('https://') ? t : null;
}

DateTime? _date(Object? v) => v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

final storiesDataProvider = StreamProvider<DataResult<StoriesData>>(
  (ref) => ref.watch(offlineFirstLoaderProvider).watch('stories.json', StoriesData.fromJson),
);

/// Yayındaki hikâyeler; izlenmemişler öne alınır.
final activeStoriesProvider = Provider<List<Story>>((ref) {
  final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
  final all = ref.watch(storiesDataProvider).value?.data.activeAt(now) ?? const <Story>[];
  final seen = ref.watch(seenStoriesProvider);
  return [
    ...all.where((s) => !seen.contains(s.seenKey)),
    ...all.where((s) => seen.contains(s.seenKey)),
  ];
});

/// İzlenen hikâyeler (cihazda, Hive "stories_seen").
final seenStoriesProvider = NotifierProvider<SeenStoriesNotifier, Set<String>>(SeenStoriesNotifier.new);

class SeenStoriesNotifier extends Notifier<Set<String>> {
  static const storeKey = 'stories_seen';

  @override
  Set<String> build() {
    final raw = ref.watch(reminderStoreProvider).read(storeKey);
    if (raw == null) return const {};
    try {
      return {for (final v in jsonDecode(raw) as List<dynamic>) v as String};
    } catch (_) {
      return const {};
    }
  }

  Future<void> markSeen(Story story) async {
    if (state.contains(story.seenKey)) return;
    // Eski sürüm anahtarlarını at (aynı hikâyenin önceki içerikleri), en fazla 200 kayıt.
    final next = {
      ...state.where((k) => !k.startsWith('${story.id}:')),
      story.seenKey,
    };
    final trimmed = next.length > 200 ? next.skip(next.length - 200).toSet() : next;
    state = trimmed;
    await ref.read(reminderStoreProvider).write(storeKey, jsonEncode(trimmed.toList()));
  }
}
