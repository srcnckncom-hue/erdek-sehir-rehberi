import 'package:erdek_rehberi/features/contacts/domain/contacts.dart';
import 'package:erdek_rehberi/features/explore/domain/explore.dart';
import 'package:erdek_rehberi/features/pharmacy/domain/pharmacy.dart';
import 'package:erdek_rehberi/features/search/domain/search_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pharmacy = PharmacyData.fromJson({
    'pharmacies': [
      {'id': 'a', 'name': 'Merkez Eczanesi', 'address': 'Yalı Cd.', 'phone': '+900000000000'},
      {'id': 'b', 'name': 'Deniz Eczanesi', 'address': 'Çarşı', 'phone': '+900000000000'},
    ],
    'duties': <Map<String, dynamic>>[],
  });
  final contacts = ContactsData.fromJson({
    'categories': [
      {
        'id': 'kamu',
        'title': 'Kamu Kurumları',
        'contacts': [
          {'name': 'Erdek Belediyesi', 'phone': '+900000000000'},
          {'name': 'Liman Başkanlığı', 'phone': '+900000000000'},
        ],
      },
    ],
  });

  test('2 harften kısa sorgu sonuç vermez', () {
    expect(searchAll(query: 'e', now: DateTime(2026), pharmacy: pharmacy).isEmpty, isTrue);
  });

  test('eczane adı ve adreste, Türkçe harf duyarsız', () {
    final r = searchAll(query: 'carsi', now: DateTime(2026), pharmacy: pharmacy);
    expect(r.pharmacies.map((p) => p.name), ['Deniz Eczanesi']);
  });

  test('telefonlarda kategori adıyla da bulunur', () {
    final r = searchAll(query: 'kamu', now: DateTime(2026), contacts: contacts);
    expect(r.contacts, hasLength(2));
    final r2 = searchAll(query: 'LİMAN', now: DateTime(2026), contacts: contacts);
    expect(r2.contacts.single.name, 'Liman Başkanlığı');
  });

  test('gezilecek yerlerde başlık ve özette arar', () {
    final places = PlacesData.fromJson({
      'places': [
        {
          'id': 'a',
          'title': 'Zeytin Adası',
          'area': 'erdek',
          'category': 'manzara',
          'summary': 'Kıyıya yakın küçük ada.',
          'paragraphs': ['Metin'],
        },
        {
          'id': 'b',
          'title': 'Orman Yolu',
          'area': 'kapidag',
          'category': 'doga',
          'summary': 'Çam ormanı içinde yürüyüş.',
          'paragraphs': ['Metin'],
        },
      ],
    });
    expect(searchAll(query: 'ZEYTIN', now: DateTime(2026), places: places).places.single.id, 'a');
    expect(searchAll(query: 'cam orman', now: DateTime(2026), places: places).places.single.id, 'b');
  });
}
