import 'dart:io';

import 'package:erdek_rehberi/app/providers.dart';
import 'package:erdek_rehberi/core/data/json_sources.dart';
import 'package:erdek_rehberi/features/erdekspor/erdekspor.dart';
import 'package:erdek_rehberi/features/erdekspor/erdekspor_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _club = File('test/fixtures/erdekspor_club.html').readAsStringSync();
final _group = File('test/fixtures/erdekspor_group.html').readAsStringSync();

class _FakeFetcher implements HtmlFetcher {
  bool fail = false;
  final urls = <String>[];

  @override
  Future<String> get(String url) async {
    urls.add(url);
    if (fail) throw const SocketException('çevrimdışı');
    return url.contains('/grup/') ? _group : _club;
  }
}

void main() {
  test('kulüp sayfası: maçlar, skor, iç saha/deplasman, istatistik, form', () {
    final club = parseClubPage(_club);
    expect(club.season, '2026/2027');
    expect(club.matches, hasLength(4));

    final gomec = club.matches[1];
    expect(gomec.played, isTrue);
    expect(gomec.isHome, isFalse);
    expect(gomec.opponent, 'Gömeç Belediyespor');
    expect((gomec.homeGoals, gomec.awayGoals), (1, 1));
    expect(gomec.outcome, MatchOutcome.drawn);
    expect(gomec.round, 1);
    expect(gomec.group, 'Süper Amatör A Grubu');
    expect(gomec.dateText, '24.10.2026 Cmt · 14:30');
    expect(gomec.stadium, 'Gömeç Stadı');
    expect(gomec.detailUrl, 'https://balikesiraskf.com/mac-detay.php?id=5922');
    expect(club.matches[2].outcome, MatchOutcome.won);

    final u12 = club.matches[3];
    expect(u12.played, isFalse);
    expect(u12.kickoff, isNull);
    expect(u12.dateText, isNull);

    expect(club.stats.metrics['Oynanan maç'], '5');
    expect(club.stats.metrics['Gol averajı'], '+2');
    expect(club.stats.metrics['Galibiyet oranı'], '%40');
    expect(club.stats.form.map((f) => f.$1), [MatchOutcome.won, MatchOutcome.drawn, MatchOutcome.lost]);
    expect(club.stats.form.first.$2, 'Galibiyet · Erdekspor 3 - 0 Burhaniye Körfezgücü SK');
    expect(club.stats.splits.single.$1, 'İç saha');
    expect(club.stats.splits.single.$2, contains('5 atılan / 3 yenilen gol'));

    final (group, url) = mainGroupOf(club.matches, club.groupLinks);
    expect(group, 'Süper Amatör A Grubu');
    expect(url, 'https://balikesiraskf.com/grup/super-amator-lig-super-amator-a-grubu-2026-2027');
  });

  test('puan durumu: yalnızca puan tablosu, eksi averaj, Erdekspor işaretli', () {
    final rows = parseStandings(_group);
    expect(rows.map((r) => r.rank), [1, 5, 10]);
    expect(rows[1].team, 'Erdekspor');
    expect(rows[1].isClub, isTrue);
    expect(rows[1].points, 8);
    expect(rows[2].goalDiff, -11);
  });

  test('fikstür/sonuç sıralaması ve lig süzgeci', () {
    final club = parseClubPage(_club);
    final data = ErdeksporData(matches: club.matches, stats: club.stats, standings: const []);
    expect(data.leagues, hasLength(2));
    final main = data.leagues.first;
    expect(data.results(main).map((m) => m.round), [2, 1]); // yeniden eskiye
    expect(data.fixtures(main).single.opponent, 'Bigadiç Spor');
    expect(data.fixtures().last.kickoff, isNull); // tarihsiz sona
  });

  test('önbellek: taze kopya varsa ağa çıkılmaz; çevrimdışıyken son kopya', () async {
    final fetcher = _FakeFetcher();
    var now = DateTime(2026, 11, 22, 18);
    final cache = MemoryJsonCache();
    ProviderContainer container() {
      final c = ProviderContainer(overrides: [
        htmlFetcherProvider.overrideWithValue(fetcher),
        jsonCacheProvider.overrideWithValue(cache),
        clockProvider.overrideWithValue(() => now),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    final first = await container().read(erdeksporProvider.future);
    expect(first!.standings, hasLength(3));
    expect(fetcher.urls, hasLength(2));

    now = now.add(const Duration(minutes: 5));
    await container().read(erdeksporProvider.future);
    expect(fetcher.urls, hasLength(2)); // önbellekten

    now = now.add(const Duration(hours: 1));
    fetcher.fail = true;
    final c = container();
    final offline = await c.read(erdeksporProvider.future);
    expect(offline!.matches, hasLength(4));
    expect(c.read(erdeksporProvider.notifier).refreshFailed, isTrue);
  });
}
