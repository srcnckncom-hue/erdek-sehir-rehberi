import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

/// Balıkesir ASKF sitesinden (balikesiraskf.com) Erdekspor verisi.
abstract final class ErdeksporSource {
  static const base = 'https://balikesiraskf.com';
  static const clubUrl = '$base/takim/erdekspor';

  /// Puan durumu bağlantısı kulüp sayfasından bulunamazsa (güncel sezon).
  static const fallbackGroupUrl = '$base/grup/super-amator-lig-super-amator-a-grubu-2026-2027';
  static const mainLeague = 'Süper Amatör';
  static const clubName = 'Erdekspor';
}

enum MatchOutcome { won, drawn, lost }

@immutable
class ClubMatch {
  const ClubMatch({
    required this.round,
    required this.league,
    required this.home,
    required this.away,
    required this.isHome,
    required this.played,
    this.homeGoals,
    this.awayGoals,
    this.status,
    this.kickoff,
    this.dateText,
    this.stadium,
    this.detailUrl,
  });

  final int? round;

  /// "Süper Amatör Lig · Süper Amatör A Grubu"
  final String league;
  final String home;
  final String away;
  final bool isHome;
  final bool played;
  final int? homeGoals;
  final int? awayGoals;

  /// Sitedeki durum metni: "Galibiyet", "Beraberlik", "Program"…
  final String? status;
  final DateTime? kickoff;

  /// "24.10.2026 Cmt · 14:30"
  final String? dateText;
  final String? stadium;
  final String? detailUrl;

  String get opponent => isHome ? away : home;

  /// Ligin kısa adı: "Süper Amatör A Grubu" (· sonrası) ya da tamamı.
  String get group => league.contains('·') ? league.split('·').last.trim() : league;

  MatchOutcome? get outcome {
    final h = homeGoals;
    final a = awayGoals;
    if (!played || h == null || a == null) return null;
    final mine = isHome ? h : a;
    final theirs = isHome ? a : h;
    return mine > theirs ? MatchOutcome.won : (mine == theirs ? MatchOutcome.drawn : MatchOutcome.lost);
  }
}

@immutable
class ClubStats {
  const ClubStats({this.metrics = const {}, this.form = const [], this.splits = const []});

  /// "Oynanan maç" → "5", "Gol averajı" → "+2", "Galibiyet oranı" → "%40"…
  final Map<String, String> metrics;

  /// Son 5 maç (eskiden yeniye): sonuç + başlık ("Galibiyet · Erdekspor 3 - 0 …").
  final List<(MatchOutcome, String)> form;

  /// ("İç saha", "3 maç · 2 G · 0 B · 1 M · 5 atılan / 3 yenilen gol")
  final List<(String, String)> splits;

  bool get isEmpty => metrics.isEmpty && form.isEmpty;
}

@immutable
class StandingRow {
  const StandingRow({
    required this.rank,
    required this.team,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDiff,
    required this.points,
  });

  final int rank;
  final String team;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDiff;
  final int points;

  bool get isClub => team.toLowerCase().contains(ErdeksporSource.clubName.toLowerCase());
}

@immutable
class ErdeksporData {
  const ErdeksporData({
    required this.matches,
    required this.stats,
    required this.standings,
    this.groupName,
    this.season,
    this.fetchedAt,
  });

  final List<ClubMatch> matches;
  final ClubStats stats;
  final List<StandingRow> standings;

  /// Puan durumunun grubu: "Süper Amatör A Grubu".
  final String? groupName;

  /// "2026/2027"
  final String? season;
  final DateTime? fetchedAt;

  List<String> get leagues => [...{for (final m in matches) m.league}];

  /// Oynananlar yeniden eskiye.
  List<ClubMatch> results([String? league]) => [
        for (final m in matches)
          if (m.played && (league == null || m.league == league)) m,
      ]..sort((a, b) => (b.kickoff ?? DateTime(0)).compareTo(a.kickoff ?? DateTime(0)));

  /// Oynanmayanlar yakından uzağa (tarihsizler sona).
  List<ClubMatch> fixtures([String? league]) => [
        for (final m in matches)
          if (!m.played && (league == null || m.league == league)) m,
      ]..sort((a, b) => (a.kickoff ?? DateTime(9999)).compareTo(b.kickoff ?? DateTime(9999)));

  ErdeksporData withFetchedAt(DateTime t) =>
      ErdeksporData(matches: matches, stats: stats, standings: standings, groupName: groupName, season: season, fetchedAt: t);
}

String _clean(String? s) => (s ?? '').replaceAll(' ', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

int? _int(String? s) => int.tryParse(_clean(s).replaceAll('+', ''));

/// Kulüp sayfası: fikstür + sonuçlar + sezon istatistikleri.
({List<ClubMatch> matches, ClubStats stats, String? season, Map<String, String> groupLinks}) parseClubPage(
  String body,
) {
  final doc = html.parse(body);
  final matches = <ClubMatch>[];
  for (final row in doc.querySelectorAll('article.club-match-row')) {
    final ctx = row.querySelectorAll('.club-match-context span').map((e) => _clean(e.text)).toList();
    final home = _clean(row.querySelector('.club-team-1 span')?.text);
    final away = _clean(row.querySelector('.club-team-2 span')?.text);
    if (home.isEmpty || away.isEmpty) continue;
    final score = _clean(row.querySelector('.club-score strong')?.text);
    final goals = RegExp(r'(\d+)\s*[–-]\s*(\d+)').firstMatch(score);
    final footer = row.querySelectorAll('.club-match-footer > span').map((e) => _clean(e.text)).toList();
    final time = int.tryParse(row.attributes['data-time'] ?? '');
    final href = row.querySelector('a.club-score')?.attributes['href'];
    matches.add(ClubMatch(
      round: int.tryParse(row.attributes['data-round'] ?? ''),
      league: ctx.length > 1 ? ctx[1] : '',
      home: home,
      away: away,
      isHome: row.attributes['data-venue'] == 'home' || (row.querySelector('.club-team-1.is-club') != null),
      played: row.attributes['data-state'] == 'played' && goals != null,
      homeGoals: goals == null ? null : int.parse(goals.group(1)!),
      awayGoals: goals == null ? null : int.parse(goals.group(2)!),
      status: _clean(row.querySelector('.club-score span')?.text).nullIfEmpty,
      kickoff: time == null || time <= 0 ? null : DateTime.fromMillisecondsSinceEpoch(time * 1000, isUtc: true),
      dateText: footer.isNotEmpty ? footer[0].nullIfEmpty : null,
      stadium: footer.length > 1 ? footer[1].nullIfEmpty : null,
      detailUrl: href == null ? null : Uri.parse(ErdeksporSource.base).resolve(href).toString(),
    ));
  }

  final metrics = <String, String>{};
  for (final m in doc.querySelectorAll('#sezon-istatistikleri .club-metric')) {
    final k = _clean(m.querySelector('span')?.text);
    final v = _clean(m.querySelector('strong')?.text);
    if (k.isNotEmpty && v.isNotEmpty) metrics[k] = v;
  }
  for (final d in doc.querySelectorAll('#sezon-istatistikleri .club-performance > div')) {
    final k = _clean(d.querySelector('span')?.text);
    final v = _clean(d.querySelector('strong')?.text);
    if (k.isNotEmpty && v.isNotEmpty) metrics[k] = v;
  }
  final form = <(MatchOutcome, String)>[
    for (final a in doc.querySelectorAll('#sezon-istatistikleri .club-form-result'))
      if (_outcomeOf(a) case final o?) (o, _clean(a.attributes['title'])),
  ];
  final splits = <(String, String)>[
    for (final d in doc.querySelectorAll('#sezon-istatistikleri .club-splits > div'))
      if (_clean(d.querySelector('strong')?.text) case final title when title.isNotEmpty)
        (title, d.querySelectorAll('span').map((e) => _clean(e.text)).where((t) => t.isNotEmpty).join(' · ')),
  ];

  final groupLinks = <String, String>{
    for (final a in doc.querySelectorAll('a[href*="/grup/"]'))
      if (_clean(a.text) case final t when t.isNotEmpty) t: a.attributes['href']!,
  };
  return (
    matches: matches,
    stats: ClubStats(metrics: metrics, form: form, splits: splits),
    season: _clean(doc.querySelector('#kulup-fiksturu .club-eyebrow')?.text).nullIfEmpty,
    groupLinks: groupLinks,
  );
}

MatchOutcome? _outcomeOf(Element a) {
  final c = a.classes;
  if (c.contains('won')) return MatchOutcome.won;
  if (c.contains('drawn')) return MatchOutcome.drawn;
  if (c.contains('lost')) return MatchOutcome.lost;
  return null;
}

/// Ana ligin (Süper Amatör) grubu ve puan durumu bağlantısı.
(String group, String url) mainGroupOf(List<ClubMatch> matches, Map<String, String> groupLinks) {
  final main = matches.where((m) => m.league.contains(ErdeksporSource.mainLeague)).firstOrNull;
  final group = main?.group ?? 'Süper Amatör A Grubu';
  final url = groupLinks[group];
  return (group, url == null ? ErdeksporSource.fallbackGroupUrl : Uri.parse(ErdeksporSource.base).resolve(url).toString());
}

/// Grup sayfası: ilk tablo puan durumu (Sıra, Takım, O, G, B, M, AG, YG, AV, P).
List<StandingRow> parseStandings(String body) {
  final doc = html.parse(body);
  final table = doc.querySelectorAll('table').where((t) {
    final head = _clean(t.querySelector('thead')?.text);
    return head.contains('Takım') && head.contains('AV');
  }).firstOrNull;
  if (table == null) return const [];
  return [
    for (final tr in table.querySelectorAll('tbody tr'))
      if (tr.querySelectorAll('td') case final td when td.length >= 10 && _int(td[0].text) != null)
        StandingRow(
          rank: _int(td[0].text)!,
          team: _clean(td[1].text),
          played: _int(td[2].text) ?? 0,
          won: _int(td[3].text) ?? 0,
          drawn: _int(td[4].text) ?? 0,
          lost: _int(td[5].text) ?? 0,
          goalsFor: _int(td[6].text) ?? 0,
          goalsAgainst: _int(td[7].text) ?? 0,
          goalDiff: int.tryParse(_clean(td[8].text).replaceAll('+', '')) ?? 0,
          points: _int(td[9].text) ?? 0,
        ),
  ];
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
