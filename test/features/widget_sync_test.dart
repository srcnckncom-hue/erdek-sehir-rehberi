import 'dart:convert';
import 'dart:io';

import 'package:erdek_rehberi/core/data/data_envelope.dart';
import 'package:erdek_rehberi/features/home_widget_sync/widget_sync.dart';
import 'package:erdek_rehberi/features/pharmacy/domain/pharmacy.dart';
import 'package:erdek_rehberi/features/prayer/domain/prayer_times.dart';
import 'package:erdek_rehberi/features/transport/domain/transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_overrides.dart';

T _load<T>(String file, T Function(Map<String, dynamic>) parse) => DataEnvelope.fromJson(
      jsonDecode(File('$fixturesDir/$file').readAsStringSync()) as Map<String, dynamic>,
      parse,
    ).data;

void main() {
  test('widget verisi: vakitler ve 08:30 nöbet pencereleri', () {
    final snap = HomeWidgetSync.buildSnapshot(
      erdekNow: testNow,
      prayer: _load('prayer_times.json', PrayerTimesData.fromJson),
      pharmacy: _load('pharmacy.json', PharmacyData.fromJson),
      days: 2,
    );
    final prayers = (snap['prayers'] as List<dynamic>).cast<Map<String, String>>();
    expect(prayers.first['name'], 'İmsak');
    expect(prayers.first['at'], startsWith('2026-11-21T'));
    expect(prayers.first['at'], endsWith('+03:00'));
    expect(prayers.length % 6, 0);

    final duties = (snap['duties'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(duties.first['from'], '2026-11-21T08:30:00+03:00');
    expect(duties.first['to'], '2026-11-22T08:30:00+03:00');
    expect(duties.first['names'], isNotEmpty);
  });

  test('widget verisi: sıradaki seferler (geçmişler yok, sıralı)', () {
    final snap = HomeWidgetSync.buildSnapshot(
      erdekNow: testNow,
      transport: _load('transport.json', TransportData.fromJson),
    );
    final departures = (snap['departures'] as List<dynamic>).cast<Map<String, String>>();
    expect(departures, isNotEmpty);
    final stamps = [for (final d in departures) d['at']!];
    expect(stamps, orderedEquals([...stamps]..sort()));
    // testNow = 21.11.2026 18:05 → bugünün geçmiş seferleri yok
    expect(stamps.first.compareTo('2026-11-21T18:05:00+03:00'), greaterThan(0));
    expect(departures.first['route'], contains('→'));
  });

  test('veri yoksa boş listeler', () {
    final snap = HomeWidgetSync.buildSnapshot(erdekNow: testNow);
    expect(snap['prayers'], isEmpty);
    expect(snap['duties'], isEmpty);
    expect(snap['departures'], isEmpty);
  });
}
