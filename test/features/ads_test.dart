import 'package:erdek_rehberi/core/data/json_sources.dart';
import 'package:erdek_rehberi/features/ads/data/ads_repository.dart';
import 'package:erdek_rehberi/features/ads/domain/ad.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Ad _ad(String id, String slot, {int priority = 0, DateTime? endsAt}) => Ad(
      id: id,
      slotId: slot,
      title: 'Reklam $id',
      imagePath: '$id.jpg',
      priority: priority,
      endsAt: endsAt,
    );

void main() {
  final now = DateTime.utc(2026, 11, 21, 12);

  test('slotta reklam yoksa null', () {
    expect(pickAd([_ad('a', 'pharmacy_bottom')], 'home_feed_1', now: now), isNull);
  });

  test('en yüksek öncelik kazanır, eşitler arasında döner', () {
    final ads = [
      _ad('a', 'home_feed_1'),
      _ad('b', 'home_feed_1', priority: 5),
      _ad('c', 'home_feed_1', priority: 5),
    ];
    expect(pickAd(ads, 'home_feed_1', now: now)!.id, 'b');
    expect(pickAd(ads, 'home_feed_1', now: now, rotation: 1)!.id, 'c');
    expect(pickAd(ads, 'home_feed_1', now: now, rotation: 2)!.id, 'b');
  });

  test('süresi biten (önbellekten gelen) reklam gösterilmez', () {
    final ads = [_ad('a', 'home_feed_1', endsAt: now.subtract(const Duration(minutes: 1)))];
    expect(pickAd(ads, 'home_feed_1', now: now), isNull);
  });

  test('get_active_ads satırı okunur', () {
    final ad = Ad.fromJson({
      'ad_id': '6f1c',
      'slot_id': 'home_feed_1',
      'title': 'Başlık',
      'advertiser': null,
      'image_path': 'x.jpg',
      'link_url': 'https://example.com',
      'priority': 2,
      'ends_at': '2026-12-01T00:00:00+00:00',
    });
    expect(ad.priority, 2);
    expect(ad.endsAt, DateTime.utc(2026, 12));
  });

  test('örnek ayarlarla ağa çıkılmaz, boş liste döner', () async {
    final repo = AdsRepository(
      dio: Dio(),
      cache: MemoryJsonCache(),
      supabaseUrl: 'https://example.supabase.co',
      apiKey: 'ornek-anon-key',
    );
    expect(repo.isConfigured, isFalse);
    expect(await repo.loadActive(), isEmpty);
    expect(
      repo.imageUrl(_ad('a', 'home_feed_1')),
      'https://example.supabase.co/storage/v1/object/public/ad-images/a.jpg',
    );
  });
}
