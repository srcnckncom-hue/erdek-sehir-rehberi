import 'package:material_ui/material_ui.dart';

import '../api.dart';
import 'content_editor.dart';
import 'form_kit.dart';

const _areas = {'erdek': 'Erdek', 'kapidag': 'Kapıdağ'};
const _categories = {
  'plaj': 'Plaj',
  'tarihi': 'Tarihî',
  'doga': 'Doğa',
  'koy': 'Köy',
  'manzara': 'Manzara',
  'diger': 'Diğer',
};

/// Gezilecek yerler. Uygulamada bu sırayla listelenir.
class PlacesEditor extends StatelessWidget {
  const PlacesEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'places',
        title: 'Gezilecek Yerler',
        validate: (data) => (data['places'] as List<dynamic>).isEmpty ? 'En az bir yer olmalı.' : null,
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
  List<dynamic> get _places => widget.data['places'] as List<dynamic>;

  void _apply(VoidCallback f) {
    setState(f);
    widget.changed();
  }

  Future<void> _edit([Map<String, dynamic>? p]) async {
    final v = await showFormDialog(
      context,
      title: p == null ? 'Yer ekle' : 'Yeri düzenle',
      fields: [
        FieldSpec('title', 'Ad', initial: p?['title'] as String?, required: true),
        FieldSpec('area', 'Bölge', kind: FieldKind.choice, options: _areas, initial: p?['area'] as String?),
        FieldSpec('category', 'Tür', kind: FieldKind.choice, options: _categories, initial: p?['category'] as String?),
        FieldSpec('summary', 'Kısa özet (listede görünür, 1–2 cümle)', kind: FieldKind.multiline,
            initial: p?['summary'] as String?, required: true),
        FieldSpec(
          'paragraphs',
          'Ayrıntılı metin',
          kind: FieldKind.multiline,
          initial: (p?['paragraphs'] as List<dynamic>?)?.join('\n\n'),
          required: true,
          hint: 'Paragrafları BOŞ SATIRLA ayırın.',
        ),
        FieldSpec(
          'tips',
          'Bilmeniz gerekenler (isteğe bağlı)',
          kind: FieldKind.multiline,
          initial: (p?['tips'] as List<dynamic>?)?.join('\n'),
          hint: 'Her satıra bir bilgi.',
        ),
        FieldSpec('address', 'Adres (isteğe bağlı)', initial: p?['address'] as String?),
        FieldSpec('latitude', 'Enlem (isteğe bağlı)', initial: p?['latitude']?.toString(),
            validator: numberValidator(min: 40, max: 41), hint: 'Yol tarifi için. Ör. 40.3991'),
        FieldSpec('longitude', 'Boylam (isteğe bağlı)', initial: p?['longitude']?.toString(),
            validator: numberValidator(min: 27, max: 28.5)),
      ],
    );
    if (v == null) return;
    final lat = parseNumber(v['latitude']!);
    final lng = parseNumber(v['longitude']!);
    if ((lat == null) != (lng == null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlem ve boylam birlikte girilmeli.')));
      }
      return;
    }
    final tips = splitLines(v['tips']!);
    final item = <String, dynamic>{
      'id': p?['id'] ?? newId('yer'),
      'title': v['title'],
      'area': v['area'],
      'category': v['category'],
      'summary': v['summary'],
      'paragraphs': splitParagraphs(v['paragraphs']!),
      if (tips.isNotEmpty) 'tips': tips,
      if (v['address']!.isNotEmpty) 'address': v['address'],
      'latitude': ?lat,
      'longitude': ?lng,
    };
    _apply(() {
      if (p == null) {
        _places.add(item);
      } else {
        _places[_places.indexOf(p)] = item;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final places = _places.cast<Map<String, dynamic>>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < places.length; i++)
          Card(
            child: ListTile(
              title: Text(places[i]['title'] as String),
              subtitle: Text(
                '${_areas[places[i]['area']]} · ${_categories[places[i]['category']]} · ${places[i]['summary']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: RowActions(
                onUp: i > 0 ? () => _apply(() => moveItem(_places, i, -1)) : null,
                onDown: i < places.length - 1 ? () => _apply(() => moveItem(_places, i, 1)) : null,
                onEdit: () => _edit(places[i]),
                onDelete: () async {
                  if (await confirmDelete(context, 'Yer')) _apply(() => _places.removeAt(i));
                },
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Yer ekle')),
        ),
      ],
    );
  }
}
