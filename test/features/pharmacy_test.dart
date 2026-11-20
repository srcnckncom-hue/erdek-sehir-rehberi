import 'package:erdek_rehberi/core/time/calendar_date.dart';
import 'package:erdek_rehberi/features/pharmacy/domain/duty_schedule.dart';
import 'package:erdek_rehberi/features/pharmacy/domain/pharmacy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dutyDateFor (nöbet 08:30\'da değişir)', () {
    test('08:29 → bir önceki gün', () {
      expect(dutyDateFor(DateTime(2026, 11, 21, 8, 29)), const CalendarDate(2026, 11, 20));
    });

    test('08:30 → bugün', () {
      expect(dutyDateFor(DateTime(2026, 11, 21, 8, 30)), const CalendarDate(2026, 11, 21));
    });

    test('gece yarısı → bir önceki gün', () {
      expect(dutyDateFor(DateTime(2026, 11, 21)), const CalendarDate(2026, 11, 20));
    });

    test('ayın 1\'i sabahı → önceki ayın son günü', () {
      expect(dutyDateFor(DateTime(2026, 12, 1, 3)), const CalendarDate(2026, 11, 30));
      expect(dutyDateFor(DateTime(2027, 1, 1, 7)), const CalendarDate(2026, 12, 31));
    });
  });

  group('PharmacyData.onDutyFor', () {
    final data = PharmacyData.fromJson({
      'pharmacies': [
        {'id': 'a', 'name': 'A', 'address': 'x', 'phone': '+900000000000'},
        {'id': 'b', 'name': 'B', 'address': 'y', 'phone': '+900000000000', 'lat': 40.4, 'lng': 27.8},
      ],
      'duties': [
        {'date': '2026-11-21', 'pharmacyIds': ['a', 'b']},
        {'date': '2026-11-22', 'pharmacyIds': ['yok', 'b']},
      ],
    });

    test('birden fazla nöbetçi eczane', () {
      expect(data.onDutyFor(const CalendarDate(2026, 11, 21)).map((p) => p.id), ['a', 'b']);
    });

    test('tanımsız kimlik atlanır', () {
      expect(data.onDutyFor(const CalendarDate(2026, 11, 22)).map((p) => p.id), ['b']);
    });

    test('kayıt yoksa boş liste', () {
      expect(data.onDutyFor(const CalendarDate(2026, 12, 25)), isEmpty);
      expect(data.lastDutyDate, const CalendarDate(2026, 11, 22));
    });

    test('konum bilgisi', () {
      expect(data.pharmacies[0].hasLocation, isFalse);
      expect(data.pharmacies[1].hasLocation, isTrue);
    });
  });
}
