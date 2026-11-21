import 'package:erdek_rehberi/core/util/text_search.dart';
import 'package:erdek_rehberi/core/util/launchers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Türkçe büyük/küçük harf ve aksan katlama', () {
    expect(TextSearch.normalize('İSKELE'), 'iskele');
    expect(TextSearch.normalize('IŞIK'), 'isik');
    expect(TextSearch.normalize('Çağlayan Öğüt'), 'caglayan ogut');
  });

  test('her kelime bir alanda geçmeli', () {
    expect(TextSearch.matches('balikli', ['Paşalimanı / Balıklı']), isTrue);
    expect(TextSearch.matches('erdek avşa', ['Erdek → Avşa']), isTrue);
    expect(TextSearch.matches('erdek marmara', ['Erdek → Avşa']), isFalse);
    expect(TextSearch.matches(' ', ['x']), isFalse);
  });

  test('telefon biçimi', () {
    expect(Launchers.formatPhone('+902665551234'), '0266 555 12 34');
    expect(Launchers.formatPhone('112'), '112');
  });
}
