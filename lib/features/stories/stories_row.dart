import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../explore/presentation/place_photos.dart';
import 'stories.dart';
import 'story_viewer.dart';

/// Ana sayfadaki yuvarlak hikâyeler (Hızlı İşlemler'in üstünde).
/// Yayında hikâye yoksa hiçbir şey çizmez.
class StoriesRow extends ConsumerWidget {
  const StoriesRow({super.key});

  static const _ringSize = 72.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(activeStoriesProvider);
    if (stories.isEmpty) return const SizedBox.shrink();
    final seen = ref.watch(seenStoriesProvider);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: SizedBox(
        height: _ringSize + 30,
        child: Semantics(
          label: l10n.storiesLabel,
          container: true,
          child: ListView.separated(
            key: const Key('stories_row'),
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.pagePadding,
            itemCount: stories.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) => StoryBubble(
              story: stories[i],
              seen: seen.contains(stories[i].seenKey),
              size: _ringSize,
              onTap: () => openStories(context, stories, i),
            ),
          ),
        ),
      ),
    );
  }
}

class StoryBubble extends StatelessWidget {
  const StoryBubble({
    super.key,
    required this.story,
    required this.seen,
    required this.onTap,
    this.size = 72,
  });

  final Story story;
  final bool seen;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fallback = ColoredBox(
      color: p.primarySoft,
      child: Center(child: AppIcon(AppIcons.announcements, size: size * 0.4, color: p.primary)),
    );

    return Semantics(
      button: true,
      label: story.title,
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('story_${story.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: size + 4,
          child: Column(
            children: [
              Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: seen
                      ? null
                      : const LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [Color(0xFFF9A825), Color(0xFFED681B), Color(0xFFD81B60), Color(0xFF8E24AA)],
                        ),
                  border: seen ? Border.all(color: p.divider, width: 2) : null,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: p.background, shape: BoxShape.circle),
                  child: ClipOval(child: PlacePhotoImage(url: story.cover, fallback: fallback)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                story.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  fontSize: 11.5,
                  color: seen ? p.textSecondary : p.textHeading,
                  fontWeight: seen ? FontWeight.w400 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
