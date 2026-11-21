import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../features/prayer/notifications/prayer_notifications.dart';
import '../../features/prayer/presentation/notification_settings_sheet.dart';
import '../../features/push/push_service.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../l10n/app_localizations.dart';
import '../providers.dart';

/// İlk açılışta bir kez: 3 tanıtım sayfası. "Geç" ya da "Başla" ile biter;
/// bir daha gösterilmez ([onboardingStoreProvider]).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished, this.initialPage = 0});

  static const pageCount = 3;

  static const skipKey = Key('onboarding_skip');
  static const nextKey = Key('onboarding_next');

  final VoidCallback onFinished;
  final int initialPage;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _controller = PageController(initialPage: widget.initialPage);
  late int _page = widget.initialPage;
  bool _finishing = false;

  bool get _isLast => _page == OnboardingScreen.pageCount - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    try {
      await ref.read(onboardingStoreProvider).markDone();
    } finally {
      if (mounted) widget.onFinished();
    }
  }

  void _next() {
    if (_isLast) {
      unawaited(_finish());
      return;
    }
    unawaited(
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _OnboardingPage(
        art: _Illustration(
          background: p.peach.background,
          foreground: p.peach.foreground,
          icon: AppIcons.pharmacy,
          satellites: [
            (AppIcons.prayer, p.mint.foreground),
            (AppIcons.bellRinging, p.iconOrange),
          ],
        ),
        title: l10n.onboarding1Title,
        body: l10n.onboarding1Body,
      ),
      _OnboardingPage(
        art: _Illustration(
          background: p.aqua.background,
          foreground: p.aqua.foreground,
          icon: AppIcons.ferry,
          satellites: [
            (AppIcons.bus, p.iconBlue),
            (AppIcons.clock, p.iconCoral),
          ],
        ),
        title: l10n.onboarding2Title,
        body: l10n.onboarding2Body,
      ),
      _OnboardingPage(
        art: _Illustration(
          background: p.primarySoft,
          foreground: p.primary,
          icon: AppIcons.contacts,
          satellites: [
            (AppIcons.announcements, p.iconOrange),
            (AppIcons.places, p.aqua.foreground),
          ],
        ),
        title: l10n.onboarding3Title,
        body: l10n.onboarding3Body,
        extra: const _NotificationCard(),
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: p.background,
        body: SafeArea(
          child: Column(
            children: [
              // Üst: "Geç" (son sayfada gizli ama yer kaplar)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.xs,
                  AppSpacing.xs,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Visibility(
                    visible: !_isLast,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton(
                      key: OnboardingScreen.skipKey,
                      onPressed: () => unawaited(_finish()),
                      child: Text(
                        l10n.onboardingSkip,
                        style: AppTypography.label.copyWith(color: p.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: pages,
                ),
              ),
              _Dots(count: OnboardingScreen.pageCount, current: _page),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: OnboardingScreen.nextKey,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: _next,
                    child: Text(_isLast ? l10n.onboardingStart : l10n.onboardingNext),
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.art,
    required this.title,
    required this.body,
    this.extra,
  });

  final _Illustration art;
  final String title;
  final String body;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Küçük ekranda (iPhone SE) görsel küçülür, içerik kaydırılabilir.
        final artSize = math.min(240.0, constraints.maxHeight * (extra == null ? 0.42 : 0.26));
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox.square(dimension: artSize, child: art),
                SizedBox(height: extra == null ? AppSpacing.xxl + AppSpacing.md : AppSpacing.xl),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.pageTitle.copyWith(color: p.textHeading),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(color: p.textSecondary),
                ),
                if (extra case final card?) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  card,
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Renkli daire içinde büyük ikon + çevresinde iki küçük ikon.
/// Sayfa ilk açıldığında küçük ikonlar yaylanarak gelir.
class _Illustration extends StatelessWidget {
  const _Illustration({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.satellites,
  });

  final Color background;
  final Color foreground;
  final AppIconData icon;
  final List<(AppIconData, Color)> satellites;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.biggest.shortestSide;
        final core = s * 0.56;
        final small = s * 0.27;
        // Sağ üst ve sol alt köşeler
        final positions = [
          Offset(s * 0.70, s * 0.10),
          Offset(s * 0.03, s * 0.63),
        ];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: reduceMotion ? 1.0 : 0.0, end: 1.0),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutBack,
          builder: (context, t, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                ),
              ),
              Center(
                child: Container(
                  width: core,
                  height: core,
                  decoration: BoxDecoration(
                    color: p.surface,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.raised(p.shadow),
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(icon, size: core * 0.46, color: foreground),
                ),
              ),
              for (var i = 0; i < satellites.length && i < positions.length; i++)
                Positioned(
                  left: positions[i].dx,
                  top: positions[i].dy,
                  child: Transform.scale(
                    scale: t.clamp(0.0, 1.2),
                    child: Container(
                      width: small,
                      height: small,
                      decoration: BoxDecoration(
                        color: p.surface,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.card(p.shadow),
                      ),
                      alignment: Alignment.center,
                      child: AppIcon(satellites[i].$1, size: small * 0.5, color: satellites[i].$2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: AppLocalizations.of(context).onboardingPageLabel(current + 1, count),
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                width: i == current ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == current ? p.primary : p.divider,
                  borderRadius: AppRadius.pillAll,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Son sayfa: vakit bildirimlerini aç (iOS izni burada istenir).
class _NotificationCard extends ConsumerWidget {
  const _NotificationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final enabled = ref.watch(prayerNotificationSettingsProvider.select((s) => s.enabled));
    final pushAvailable = ref.watch(pushAvailableProvider);
    return Material(
      color: p.surface,
      borderRadius: AppRadius.cardAll,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile.adaptive(
            value: enabled,
            onChanged: (on) => toggleNotifications(context, ref, on: on),
            secondary: AppIcon(AppIcons.bellRinging, size: 26, color: p.iconOrange),
            title: Text(
              l10n.notificationsTitle,
              style: AppTypography.label.copyWith(color: p.textHeading),
            ),
            subtitle: Text(
              l10n.onboardingNotifBody,
              style: AppTypography.caption.copyWith(color: p.textSecondary),
            ),
          ),
          if (pushAvailable)
            SwitchListTile.adaptive(
              value: ref.watch(announcementsPushProvider),
              onChanged: (on) => toggleAnnouncementsPush(context, ref, on: on),
              secondary: AppIcon(AppIcons.announcements, size: 26, color: p.iconPurple),
              title: Text(
                l10n.announcementsPushTitle,
                style: AppTypography.label.copyWith(color: p.textHeading),
              ),
              subtitle: Text(
                l10n.announcementsPushSubtitle,
                style: AppTypography.caption.copyWith(color: p.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
