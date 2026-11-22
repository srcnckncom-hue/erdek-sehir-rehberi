import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/util/launch_or_notify.dart';
import '../../core/util/launchers.dart';
import '../../l10n/app_localizations.dart';
import 'stories.dart';

Future<void> openStories(BuildContext context, List<Story> stories, int index) =>
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => StoryViewer(stories: stories, initialIndex: index),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );

/// Tam ekran hikâye: üstte ilerleme çubukları, sağa dokun → sonraki,
/// sola dokun → önceki, basılı tut → durdur, aşağı kaydır → kapat,
/// yana kaydır → sonraki/önceki hikâye.
class StoryViewer extends ConsumerStatefulWidget {
  const StoryViewer({super.key, required this.stories, required this.initialIndex});

  final List<Story> stories;
  final int initialIndex;

  /// Bir sayfanın ekranda kalma süresi.
  static const slideDuration = Duration(seconds: 6);

  @override
  ConsumerState<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends ConsumerState<StoryViewer> with SingleTickerProviderStateMixin {
  late int _story = widget.initialIndex.clamp(0, widget.stories.length - 1);
  int _slide = 0;
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: StoryViewer.slideDuration,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _next();
    });
  double _dragY = 0;

  Story get _current => widget.stories[_story];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  /// Fotoğraf inince süreyi başlat; sonraki fotoğrafı önceden indir.
  Future<void> _start() async {
    _progress
      ..stop()
      ..value = 0;
    final story = _current;
    final slides = story.slides;
    if (_slide >= slides.length - 1) unawaited(ref.read(seenStoriesProvider.notifier).markSeen(story));
    try {
      await precacheImage(
        NetworkImage(slides[_slide].url),
        context,
        onError: (_, _) {},
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // İnemese de süre işlesin (fotoğraf yerinde uyarı görünür).
    }
    if (!mounted || story != _current) return;
    if (_slide + 1 < slides.length) {
      precacheImage(NetworkImage(slides[_slide + 1].url), context, onError: (_, _) {}).ignore();
    }
    await _progress.forward(from: 0).orCancel.catchError((_) {});
  }

  void _close() => Navigator.of(context).maybePop();

  void _next() {
    if (_slide + 1 < _current.slides.length) {
      setState(() => _slide++);
    } else if (_story + 1 < widget.stories.length) {
      setState(() {
        _story++;
        _slide = 0;
      });
    } else {
      _close();
      return;
    }
    _start();
  }

  void _previous() {
    if (_slide > 0) {
      setState(() => _slide--);
    } else if (_story > 0) {
      setState(() {
        _story--;
        _slide = 0;
      });
    } else {
      _progress.forward(from: 0);
      return;
    }
    _start();
  }

  void _jumpStory(int delta) {
    final target = _story + delta;
    if (target < 0) return;
    if (target >= widget.stories.length) {
      _close();
      return;
    }
    setState(() {
      _story = target;
      _slide = 0;
    });
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final story = _current;
    final slide = story.slides[_slide.clamp(0, story.slides.length - 1)];
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final width = MediaQuery.sizeOf(context).width;
          if (details.globalPosition.dx < width / 3) {
            _previous();
          } else {
            _next();
          }
        },
        onLongPressStart: (_) => _progress.stop(),
        onLongPressEnd: (_) => _progress.forward(),
        onVerticalDragUpdate: (d) => setState(() => _dragY = (_dragY + d.delta.dy).clamp(0.0, 400.0)),
        onVerticalDragEnd: (d) {
          if (_dragY > 100 || (d.primaryVelocity ?? 0) > 700) {
            _close();
          } else {
            setState(() => _dragY = 0);
          }
        },
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -300) _jumpStory(1);
          if (v > 300) _jumpStory(-1);
        },
        child: Transform.translate(
          offset: Offset(0, _dragY),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                slide.url,
                key: ValueKey(slide.url),
                fit: BoxFit.contain,
                gaplessPlayback: true,
                semanticLabel: slide.caption ?? story.title,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorBuilder: (context, _, _) => Center(
                  child: Text(l10n.storyImageError, style: const TextStyle(color: Colors.white70)),
                ),
              ),
              // Üst: ilerleme çubukları + başlık + kapat
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(12, padding.top + 8, 4, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x99000000), Color(0x00000000)],
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(
                          children: [
                            for (var i = 0; i < story.slides.length; i++) ...[
                              if (i > 0) const SizedBox(width: 4),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: SizedBox(
                                    height: 3,
                                    child: i == _slide
                                        ? AnimatedBuilder(
                                            animation: _progress,
                                            builder: (_, _) => LinearProgressIndicator(
                                              value: _progress.value,
                                              backgroundColor: Colors.white30,
                                              color: Colors.white,
                                            ),
                                          )
                                        : ColoredBox(color: i < _slide ? Colors.white : Colors.white30),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ClipOval(
                            child: SizedBox.square(
                              dimension: 32,
                              child: Image.network(
                                story.cover,
                                fit: BoxFit.cover,
                                errorBuilder: (context, _, _) => const ColoredBox(color: Colors.white24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              story.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                          IconButton(
                            key: const Key('story_close'),
                            tooltip: l10n.close,
                            onPressed: _close,
                            icon: AppIcon(AppIcons.close, size: 26, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Alt: yazı + bağlantı
              if (slide.caption != null || slide.link != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20, 40, 20, padding.bottom + 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xB3000000), Color(0x00000000)],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (slide.caption case final caption?)
                          Text(
                            caption,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                          ),
                        if (slide.link case final link?) ...[
                          const SizedBox(height: 14),
                          FilledButton(
                            key: const Key('story_link'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () {
                              _progress.stop();
                              launchOrNotify(context, () => Launchers.openUrl(link));
                            },
                            child: Text(slide.linkLabel ?? l10n.storyOpenLink),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
