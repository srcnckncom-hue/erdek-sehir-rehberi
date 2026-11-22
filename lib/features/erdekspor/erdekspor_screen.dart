import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/launch_or_notify.dart';
import '../../core/util/launchers.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'erdekspor.dart';
import 'erdekspor_repository.dart';

Future<void> openErdekspor(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ErdeksporScreen()),
    );

enum ErdeksporTab { fixtures, results, standings, stats }

/// Erdekspor: fikstür, sonuçlar, puan durumu, sezon istatistikleri
/// (Balıkesir ASKF sitesinden; aşağı çekince yenilenir).
class ErdeksporScreen extends ConsumerStatefulWidget {
  const ErdeksporScreen({super.key});

  @override
  ConsumerState<ErdeksporScreen> createState() => _ErdeksporScreenState();
}

class _ErdeksporScreenState extends ConsumerState<ErdeksporScreen> {
  var _tab = ErdeksporTab.fixtures;
  String? _league;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final async = ref.watch(erdeksporProvider);
    final data = async.value;
    final leagues = data?.leagues ?? const <String>[];
    // Varsayılan: Süper Amatör (ana lig); yoksa ilki.
    final league = leagues.contains(_league)
        ? _league
        : leagues.where((l) => l.contains(ErdeksporSource.mainLeague)).firstOrNull ?? leagues.firstOrNull;

    final children = <Widget>[
      PageHeader(
        title: l10n.erdeksporTitle,
        subtitle: [?data?.season, ?data?.groupName].join(' · ').isEmpty
            ? l10n.erdeksporSubtitle
            : [?data?.season, ?data?.groupName].join(' · '),
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.back,
      ),
      SegmentedPills<ErdeksporTab>(
        key: const Key('erdekspor_tabs'),
        options: [
          SegmentOption(value: ErdeksporTab.fixtures, label: l10n.erdeksporFixtures),
          SegmentOption(value: ErdeksporTab.results, label: l10n.erdeksporResults),
          SegmentOption(value: ErdeksporTab.standings, label: l10n.erdeksporStandings),
          SegmentOption(value: ErdeksporTab.stats, label: l10n.erdeksporStats),
        ],
        selected: _tab,
        onSelected: (t) => setState(() => _tab = t),
      ),
      const SizedBox(height: AppSpacing.md),
    ];

    if (data == null) {
      children.add(async.hasError
          ? MessageView(
              key: const Key('erdekspor_error'),
              icon: AppIcons.info,
              title: l10n.erdeksporErrorTitle,
              message: l10n.erdeksporErrorMessage,
              actionLabel: l10n.retry,
              onAction: () => ref.invalidate(erdeksporProvider),
            )
          : const Padding(padding: AppSpacing.pagePadding, child: SkeletonBox(height: 160, radius: AppRadius.card)));
    } else {
      if ((_tab == ErdeksporTab.fixtures || _tab == ErdeksporTab.results) && leagues.length > 1) {
        children.addAll([
          PillChoiceRow(
            key: const Key('erdekspor_leagues'),
            items: [
              for (final lg in leagues)
                PillChoice(
                  label: lg.contains('·') ? lg.split('·').first.trim() : lg,
                  selected: lg == league,
                  onTap: () => setState(() => _league = lg),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ]);
      }
      children.addAll(switch (_tab) {
        ErdeksporTab.fixtures => _matches(context, data.fixtures(league), empty: l10n.erdeksporNoFixtures),
        ErdeksporTab.results => _matches(context, data.results(league), empty: l10n.erdeksporNoResults),
        ErdeksporTab.standings => [_StandingsTable(rows: data.standings, group: data.groupName)],
        ErdeksporTab.stats => [_StatsView(stats: data.stats)],
      });
      children.addAll([
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: AppSpacing.pagePadding,
          child: Text(
            [
              l10n.erdeksporSource,
              if (data.fetchedAt case final t?) l10n.erdeksporUpdated(_hm(t.toLocal())),
              if (ref.read(erdeksporProvider.notifier).refreshFailed) l10n.erdeksporOffline,
            ].join(' · '),
            style: AppTypography.tabLabel.copyWith(color: p.textSecondary),
          ),
        ),
        Center(
          child: TextButton.icon(
            key: const Key('erdekspor_site'),
            onPressed: () => unawaited(launchOrNotify(context, () => Launchers.openUrl(ErdeksporSource.clubUrl))),
            icon: AppIcon(AppIcons.globe, size: 18, color: p.primary),
            label: Text(l10n.erdeksporOpenSite),
          ),
        ),
      ]);
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(erdeksporProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
          children: children,
        ),
      ),
    );
  }

  static String _hm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  List<Widget> _matches(BuildContext context, List<ClubMatch> list, {required String empty}) {
    if (list.isEmpty) return [MessageView(icon: AppIcons.erdekspor, title: empty)];
    return [
      for (final m in list) ...[
        _MatchCard(match: m),
        const SizedBox(height: AppSpacing.sm),
      ],
    ];
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final ClubMatch match;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final m = match;
    final outcome = m.outcome;
    final (Color badge, String badgeText) = switch (outcome) {
      MatchOutcome.won => (p.mint.foreground, l10n.erdeksporWon),
      MatchOutcome.drawn => (p.iconOrange, l10n.erdeksporDrawn),
      MatchOutcome.lost => (p.accentRed, l10n.erdeksporLost),
      null => (p.primary, m.isHome ? l10n.erdeksporHome : l10n.erdeksporAway),
    };
    TextStyle team(bool club) => AppTypography.label.copyWith(
          color: p.textHeading,
          fontWeight: club ? FontWeight.w700 : FontWeight.w500,
        );
    final score = m.played ? '${m.homeGoals} – ${m.awayGoals}' : '–';

    return Padding(
      padding: AppSpacing.pagePadding,
      child: Material(
        color: p.surface,
        borderRadius: AppRadius.cardAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: m.detailUrl == null
              ? null
              : () => unawaited(launchOrNotify(context, () => Launchers.openUrl(m.detailUrl!))),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        [if (m.round case final r?) l10n.erdeksporRound(r), m.group].join(' · '),
                        style: AppTypography.tabLabel.copyWith(color: p.textSecondary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(color: badge.withValues(alpha: 0.12), borderRadius: AppRadius.pillAll),
                      child: Text(badgeText, style: AppTypography.tabLabel.copyWith(color: badge, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: Text(m.home, textAlign: TextAlign.end, style: team(m.isHome))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(score, style: AppTypography.cardTitle.copyWith(color: p.textHeading)),
                    ),
                    Expanded(child: Text(m.away, style: team(!m.isHome))),
                  ],
                ),
                if (m.dateText != null || m.stadium != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    [?m.dateText, ?m.stadium].join(' · '),
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(color: p.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({required this.rows, this.group});

  final List<StandingRow> rows;
  final String? group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    if (rows.isEmpty) return MessageView(icon: AppIcons.erdekspor, title: l10n.erdeksporNoStandings);
    final h = AppTypography.tabLabel.copyWith(color: p.textSecondary, fontWeight: FontWeight.w600);
    Widget cell(String t, {TextStyle? style, double w = 28}) =>
        SizedBox(width: w, child: Text(t, textAlign: TextAlign.center, style: style));
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Container(
        key: const Key('erdekspor_standings'),
        decoration: BoxDecoration(color: p.surface, borderRadius: AppRadius.cardAll),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  cell('#', style: h, w: 24),
                  Expanded(child: Text(l10n.erdeksporTeam, style: h)),
                  for (final c in ['O', 'G', 'B', 'M', 'AV']) cell(c, style: h),
                  cell('P', style: h, w: 32),
                ],
              ),
            ),
            for (final r in rows)
              Container(
                key: Key('standing_${r.rank}'),
                color: r.isClub ? p.primary.withValues(alpha: 0.10) : null,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    cell('${r.rank}', w: 24, style: AppTypography.caption.copyWith(color: p.textSecondary)),
                    Expanded(
                      child: Text(
                        r.team,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: p.textHeading,
                          fontWeight: r.isClub ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    for (final v in [r.played, r.won, r.drawn, r.lost])
                      cell('$v', style: AppTypography.caption.copyWith(color: p.textBody)),
                    cell(r.goalDiff > 0 ? '+${r.goalDiff}' : '${r.goalDiff}',
                        style: AppTypography.caption.copyWith(color: p.textBody)),
                    cell('${r.points}', w: 32, style: AppTypography.label.copyWith(color: p.textHeading)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView({required this.stats});

  final ClubStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    if (stats.isEmpty) return MessageView(icon: AppIcons.erdekspor, title: l10n.erdeksporNoStats);
    Color formColor(MatchOutcome o) => switch (o) {
          MatchOutcome.won => p.mint.foreground,
          MatchOutcome.drawn => p.iconOrange,
          MatchOutcome.lost => p.accentRed,
        };
    String formLetter(MatchOutcome o) => switch (o) {
          MatchOutcome.won => l10n.erdeksporFormWon,
          MatchOutcome.drawn => l10n.erdeksporFormDrawn,
          MatchOutcome.lost => l10n.erdeksporFormLost,
        };
    return Column(
      key: const Key('erdekspor_stats'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppSpacing.pagePadding,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final e in stats.metrics.entries)
                Container(
                  width: 104,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: p.surface, borderRadius: AppRadius.cardAll),
                  child: Column(
                    children: [
                      Text(e.value, style: AppTypography.cardTitle.copyWith(color: p.textHeading)),
                      const SizedBox(height: 2),
                      Text(
                        e.key,
                        textAlign: TextAlign.center,
                        style: AppTypography.tabLabel.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (stats.form.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.section),
          SectionHeader(title: l10n.erdeksporForm),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: AppSpacing.pagePadding,
            child: Row(
              children: [
                for (final (o, title) in stats.form)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Tooltip(
                      message: title,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: formColor(o),
                        child: Text(formLetter(o), style: AppTypography.label.copyWith(color: Colors.white)),
                      ),
                    ),
                  ),
                Text(l10n.erdeksporNewest, style: AppTypography.tabLabel.copyWith(color: p.textSecondary)),
              ],
            ),
          ),
        ],
        if (stats.splits.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.section),
          GroupedCard(
            children: [
              for (final (title, text) in stats.splits)
                ListTile(
                  title: Text(title, style: AppTypography.label.copyWith(color: p.textHeading)),
                  subtitle: Text(text, style: AppTypography.caption.copyWith(color: p.textSecondary)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
