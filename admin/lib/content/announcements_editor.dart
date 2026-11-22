import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../screens/push_screen.dart';
import 'content_editor.dart';
import 'form_kit.dart';

const _categories = {'genel': 'Genel', 'kesinti': 'Kesinti', 'pazar': 'Pazar', 'etkinlik': 'Etkinlik'};

/// Duyurular. Bitiş tarihi geçen duyuru uygulamada kendiliğinden kalkar.
/// Her duyurunun yanındaki ✈ düğmesi onu anlık bildirim olarak da gönderir
/// (kesinti vb. acil durumlar).
class AnnouncementsEditor extends StatelessWidget {
  const AnnouncementsEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'announcements',
        title: 'Duyurular',
        builder: (context, data, changed) => _Body(api: api, data: data, changed: changed),
      );
}

class _Body extends StatefulWidget {
  const _Body({required this.api, required this.data, required this.changed});

  final Api api;
  final Map<String, dynamic> data;
  final VoidCallback changed;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  List<dynamic> get _items => widget.data['items'] as List<dynamic>;

  static String _clip(String text, int max) {
    final t = text.trim();
    return t.length <= max ? t : '${t.substring(0, max - 1)}…';
  }

  Future<void> _edit([Map<String, dynamic>? a]) async {
    final v = await showFormDialog(
      context,
      title: a == null ? 'Duyuru ekle' : 'Duyuruyu düzenle',
      fields: [
        FieldSpec('category', 'Tür', kind: FieldKind.choice, options: _categories, initial: a?['category'] as String?),
        FieldSpec('title', 'Başlık', initial: a?['title'] as String?, required: true),
        FieldSpec('body', 'Metin', kind: FieldKind.multiline, initial: a?['body'] as String?, required: true),
        FieldSpec('startsAt', 'Başlangıç günü', kind: FieldKind.date, initial: datePart(a?['startsAt'] as String?)),
        FieldSpec(
          'endsAt',
          'Bitiş günü (bu günden sonra listeden kalkar)',
          kind: FieldKind.date,
          initial: datePart(a?['endsAt'] as String?),
        ),
        FieldSpec('link', 'Bağlantı (isteğe bağlı)', initial: a?['link'] as String?, validator: httpsValidator),
      ],
    );
    if (v == null) return;
    if (v['startsAt']!.isNotEmpty && v['endsAt']!.isNotEmpty && v['endsAt']!.compareTo(v['startsAt']!) < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitiş günü başlangıçtan önce olamaz.')));
      }
      return;
    }
    final item = <String, dynamic>{
      'id': a?['id'] ?? newId('duyuru'),
      'category': v['category'],
      'title': v['title'],
      'body': v['body'],
      'publishedAt': a?['publishedAt'] ?? trNow(),
      if (v['startsAt']!.isNotEmpty) 'startsAt': '${v['startsAt']}T00:00:00+03:00',
      if (v['endsAt']!.isNotEmpty) 'endsAt': '${v['endsAt']}T23:59:00+03:00',
      if (v['link']!.isNotEmpty) 'link': v['link'],
    };
    setState(() {
      if (a == null) {
        _items.insert(0, item);
      } else {
        _items[_items.indexOf(a)] = item;
      }
    });
    widget.changed();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items.cast<Map<String, dynamic>>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: const Text('Duyuru ekle'),
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty) const Text('Duyuru yok.'),
        for (final a in items)
          Card(
            child: ListTile(
              title: Text(a['title'] as String),
              subtitle: Text([
                _categories[a['category']] ?? '',
                if (a['startsAt'] != null || a['endsAt'] != null)
                  '${trDateText(datePart(a['startsAt'] as String?))} – ${trDateText(datePart(a['endsAt'] as String?))}',
                a['body'] as String,
              ].join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Bildirim olarak gönder',
                    icon: const Icon(Icons.send_outlined),
                    onPressed: () => confirmAndSendPush(
                      context,
                      widget.api,
                      title: _clip(a['title'] as String, 80),
                      body: _clip(a['body'] as String, 240),
                    ),
                  ),
                  RowActions(
                onEdit: () => _edit(a),
                onDelete: () async {
                  if (await confirmDelete(context, 'Duyuru')) {
                    setState(() => _items.remove(a));
                    widget.changed();
                  }
                },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
