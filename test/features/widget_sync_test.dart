import 'dart:convert';
import 'dart:io';

import 'package:erdek_rehberi/core/data/data_envelope.dart';
import 'package:erdek_rehberi/features/home_widget_sync/widget_sync.dart';
import 'package:erdek_rehberi/features/pharmacy/domain/pharmacy.dart';
import 'package:erdek_rehberi/features/prayer/domain/prayer_times.dart';
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

  test('veri yoksa boş listeler', () {
    final snap = HomeWidgetSync.buildSnapshot(erdekNow: testNow);
    expect(snap['prayers'], isEmpty);
    expect(snap['duties'], isEmpty);
  });
}
