import 'package:erdek_rehberi/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Uygulama açılır ve başlığı gösterir', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ErdekApp()));
    await tester.pumpAndSettle();

    expect(find.text('Erdek Şehir Rehberi'), findsOneWidget);
  });
}
