import 'dart:convert';
import 'dart:io';

import 'package:erdek_rehberi/core/data/data_envelope.dart';
import 'package:erdek_rehberi/features/announcements/domain/announcement.dart';
import 'package:erdek_rehberi/features/appearance/appearance.dart';
import 'package:erdek_rehberi/features/businesses/domain/business.dart';
import 'package:erdek_rehberi/features/contacts/domain/contacts.dart';
import 'package:erdek_rehberi/features/events/events.dart';
import 'package:erdek_rehberi/features/explore/domain/explore.dart';
import 'package:erdek_rehberi/features/markets/markets.dart';
import 'package:erdek_rehberi/features/outages/outages.dart';
import 'package:erdek_rehberi/features/pharmacy/domain/pharmacy.dart';
import 'package:erdek_rehberi/features/prayer/domain/prayer_times.dart';
import 'package:erdek_rehberi/features/sea/sea.dart';
import 'package:erdek_rehberi/features/social/social_links.dart';
import 'package:erdek_rehberi/features/stories/stories.dart';
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

  test('places.json', () {
    final env = _load('places.json', PlacesData.fromJson);
    expect(env.data.places, isNotEmpty);
    for (final p in env.data.places) {
      expect(p.paragraphs, isNotEmpty, reason: p.id);
    }
  });

  test('history.json', () {
    final env = _load('history.json', HistoryData.fromJson);
    expect(env.data.sections, isNotEmpty);
  });

  test('businesses.json', () {
    final env = _load('businesses.json', BusinessesData.fromJson);
    expect(env.data.categories, isNotEmpty);
    final ids = {for (final c in env.data.categories) c.id};
    for (final b in env.data.businesses) {
      expect(ids, contains(b.categoryId), reason: b.id);
    }
  });

  test('social.json', () {
    _load('social.json', SocialLinks.fromJson);
  });

  test('sea.json', () {
    final env = _load('sea.json', SeaData.fromJson);
    expect(env.data.location, isNotEmpty);
  });

  test('stories.json', () {
    _load('stories.json', StoriesData.fromJson);
  });

  test('appearance.json', () {
    _load('appearance.json', AppearanceData.fromJson);
  });

  test('events.json', () {
    _load('events.json', EventsData.fromJson);
  });

  test('markets.json', () {
    _load('markets.json', MarketsData.fromJson);
  });

  test('outages.json', () {
    _load('outages.json', OutagesData.fromJson);
  });
}
