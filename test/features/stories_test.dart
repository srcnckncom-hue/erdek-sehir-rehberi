import 'package:erdek_rehberi/features/stories/stories.dart';
import 'package:erdek_rehberi/features/stories/stories_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_overrides.dart';

void main() {
  test('hikâyeler: yayın tarihleri, boş hikâye, https bağlantı', () {
    final data = StoriesData.fromJson({
      'stories': [
        {
          'id': 'a',
          'title': 'A',
          'cover': 'https://x/a.jpg',
          'slides': [
            {'url': 'https://x/1.jpg', 'link': 'http://guvensiz', 'caption': '  '},
          ],
        },
        {'id': 'bos', 'title': 'Boş', 'cover': 'https://x/b.jpg', 'slides': <Object>[]},
        {
          'id': 'gelecek',
          'title': 'Gelecek',
          'cover': 'https://x/c.jpg',
          'startsAt': '2026-12-01T00:00:00+03:00',
          'slides': [
            {'url': 'https://x/2.jpg'},
          ],
        },
      ],
    });
    final active = data.activeAt(DateTime.utc(2026, 11, 21, 12));
    expect(active.map((s) => s.id), ['a']);
    expect(active.single.slides.single.link, isNull);
    expect(active.single.slides.single.caption, isNull);
    expect(active.single.seenKey, 'a:1');
  });

  testWidgets('ana sayfa hikâye şeridi: yayındakiler, başlık altta; dokununca açılır', (tester) async {
    await tester.pumpWidget(testApp(const StoriesRow()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('stories_row')), findsOneWidget);
    expect(find.text('Kampanya'), findsOneWidget);
    expect(find.text('Etkinlikler'), findsOneWidget);
    expect(find.text('Eski'), findsNothing); // süresi bitmiş

    // Başlık yuvarlağın altında
    final circle = tester.getRect(find.byKey(const Key('story_kampanya')));
    final title = tester.getRect(find.text('Kampanya'));
    expect(title.top, greaterThan(circle.top + 60));

    await tester.tap(find.byKey(const Key('story_kampanya')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('story_close')), findsOneWidget);
    expect(find.text('Hafta sonu indirim'), findsOneWidget);

    await tester.tap(find.byKey(const Key('story_close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('story_close')), findsNothing);
  });
}
