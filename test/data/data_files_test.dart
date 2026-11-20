import 'dart:convert';
import 'dart:io';

import 'package:erdek_rehberi/core/data/data_envelope.dart';
import 'package:erdek_rehberi/features/announcements/domain/announcement.dart';
import 'package:erdek_rehberi/features/contacts/domain/contacts.dart';
import 'package:erdek_rehberi/features/pharmacy/domain/pharmacy.dart';
import 'package:erdek_rehberi/features/prayer/domain/prayer_times.dart';
import 'package:erdek_rehberi/features/transport/domain/transport.dart';
import 'package:flutter_test/flutter_test.dart';

/// data/ klasöründeki gerçek dosyalar uygulamanın modelleriyle okunabiliyor mu?
/// (Şema doğrulaması ayrıca scripts/validate_data.py ile yapılır.)
DataEnvelope<T> _load<T>(String file, T Function(Map<String, dynamic>) parse) {
  final json = jsonDecode(File('data/$file').readAsStringSync()) as Map<String, dynamic>;
  return DataEnvelope.fromJson(json, parse);
}

void main() {
  test('pharmacy.json', () {
    final env = _load('pharmacy.json', PharmacyData.fromJson);
    expect(env.data.pharmacies, isNotEmpty);
    expect(env.data.duties, isNotEmpty);
  });

  test('prayer_times.json', () {
    final env = _load('prayer_times.json', PrayerTimesData.fromJson);
    expect(env.data.days, isNotEmpty);
  });

  test('transport.json', () {
    final env = _load('transport.json', TransportData.fromJson);
    expect(env.data.byMode(TransportMode.ferry), isNotEmpty);
    expect(env.data.byMode(TransportMode.bus), isNotEmpty);
  });

  test('contacts.json', () {
    final env = _load('contacts.json', ContactsData.fromJson);
    expect(env.data.categories, isNotEmpty);
  });

  test('announcements.json', () {
    final env = _load('announcements.json', AnnouncementsData.fromJson);
    expect(env.data.items, isNotEmpty);
  });
}
