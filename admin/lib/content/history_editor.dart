import 'package:material_ui/material_ui.dart';

import '../api.dart';
import 'content_editor.dart';
import 'form_kit.dart';

/// Erdek tarihi: giriş metni + dönemler (uygulamada bu sırayla).
class HistoryEditor extends StatelessWidget {
  const HistoryEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'history',
        title: 'Erdek Tarihi',
        validate: (data) => (data['sections'] as List<dynamic>).isEmpty ? 'En az bir dönem olmalı.' : null,
        builder: (context, data, changed) => _Body(data: data, changed: changed),
      );
}

class _Body extends StatefulWidget {
  const _Body({required this.data, required this.changed});

  final Map<String, dynamic> data;
  final VoidCallback changed;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final _intro = TextEditingController(text: widget.data['intro'] as String?);

  List<dynamic> get _sections => widget.data['sections'] as List<dynamic>;

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  void _apply(VoidCallback f) {
    setState(f);
    widget.changed();
  }

  Future<void> _edit([Map<String, dynamic>? s]) async {
    final v = await showFormDialog(
      context,
      title: s == null ? 'Dönem ekle' : 'Dönemi düzenle',
      fields: [
        FieldSpec('title', 'Başlık', initial: s?['title'] as String?, required: true),
        FieldSpec('period', 'Tarih aralığı (isteğe bağlı, ör. MÖ 7. yüzyıl)', initial: s?['period'] as String?),
        FieldSpec(
          'paragraphs',
          'Metin',
          kind: FieldKind.multiline,
          initial: (s?['paragraphs'] as List<dynamic>?)?.join('\n\n'),
          required: true,
          hint: 'Paragrafları BOŞ SATIRLA ayırın.',
        ),
      ],
    );
    if (v == null) return;
    final item = <String, dynamic>{
      'id': s?['id'] ?? newId('donem'),
      'title': v['title'],
      if (v['period']!.isNotEmpty) 'period': v['period'],
      'paragraphs': splitParagraphs(v['paragraphs']!),
    };
    _apply(() {
      if (s == null) {
        _sections.add(item);
      } else {
        _sections[_sections.indexOf(s)] = item;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections.cast<Map<String, dynamic>>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _intro,
          minLines: 3,
          maxLines: 10,
          decoration: const InputDecoration(labelText: 'Giriş metni (isteğe bağlı)', border: OutlineInputBorder()),
          onChanged: (t) {
            final text = t.trim();
            if (text.isEmpty) {
              widget.data.remove('intro');
            } else {
              widget.data['intro'] = text;
            }
            widget.changed();
          },
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < sections.length; i++)
          Card(
            child: ListTile(
              title: Text(sections[i]['title'] as String),
              subtitle: Text(
                [if (sections[i]['period'] != null) sections[i]['period'], (sections[i]['paragraphs'] as List<dynamic>).first]
                    .join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: RowActions(
                onUp: i > 0 ? () => _apply(() => moveItem(_sections, i, -1)) : null,
                onDown: i < sections.length - 1 ? () => _apply(() => moveItem(_sections, i, 1)) : null,
                onEdit: () => _edit(sections[i]),
                onDelete: () async {
                  if (await confirmDelete(context, 'Dönem')) _apply(() => _sections.removeAt(i));
                },
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Dönem ekle')),
        ),
      ],
    );
  }
}
