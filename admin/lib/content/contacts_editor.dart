import 'package:material_ui/material_ui.dart';

import '../api.dart';
import 'content_editor.dart';
import 'form_kit.dart';

/// Önemli telefonlar: kategoriler ve içindeki numaralar.
class ContactsEditor extends StatelessWidget {
  const ContactsEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'contacts',
        title: 'Telefonlar',
        validate: (data) {
          final cats = data['categories'] as List<dynamic>;
          if (cats.isEmpty) return 'En az bir kategori olmalı.';
          for (final c in cats.cast<Map<String, dynamic>>()) {
            if ((c['contacts'] as List<dynamic>).isEmpty) {
              return '"${c['title']}" kategorisinde en az bir numara olmalı (ya da kategoriyi silin).';
            }
          }
          return null;
        },
        builder: (context, data, changed) => _ContactsBody(data: data, changed: changed),
      );
}

class _ContactsBody extends StatefulWidget {
  const _ContactsBody({required this.data, required this.changed});

  final Map<String, dynamic> data;
  final VoidCallback changed;

  @override
  State<_ContactsBody> createState() => _ContactsBodyState();
}

class _ContactsBodyState extends State<_ContactsBody> {
  List<dynamic> get _cats => widget.data['categories'] as List<dynamic>;

  void _apply(VoidCallback f) {
    setState(f);
    widget.changed();
  }

  Future<void> _editCategory([Map<String, dynamic>? cat]) async {
    final v = await showFormDialog(
      context,
      title: cat == null ? 'Kategori ekle' : 'Kategori adı',
      fields: [FieldSpec('title', 'Kategori adı (ör. Taksi Durakları)', initial: cat?['title'] as String?, required: true)],
    );
    if (v == null) return;
    _apply(() {
      if (cat == null) {
        _cats.add({'id': newId('kategori'), 'title': v['title'], 'contacts': <dynamic>[]});
      } else {
        cat['title'] = v['title'];
      }
    });
  }

  Future<void> _editContact(Map<String, dynamic> cat, [Map<String, dynamic>? c]) async {
    final v = await showFormDialog(
      context,
      title: c == null ? 'Numara ekle' : 'Numarayı düzenle',
      fields: [
        FieldSpec('name', 'Ad', initial: c?['name'] as String?, required: true),
        FieldSpec(
          'phone',
          'Telefon',
          initial: c == null ? null : formatPhone(c['phone'] as String),
          required: true,
          validator: phoneValidator,
          hint: '0266 123 45 67 biçiminde ya da 112 gibi kısa numara',
          keyboard: TextInputType.phone,
        ),
        FieldSpec('note', 'Not (isteğe bağlı)', initial: c?['note'] as String?),
      ],
    );
    if (v == null) return;
    final item = <String, dynamic>{'name': v['name'], 'phone': normalizePhone(v['phone']!)};
    if (v['note']!.isNotEmpty) item['note'] = v['note'];
    _apply(() {
      final list = cat['contacts'] as List<dynamic>;
      if (c == null) {
        list.add(item);
      } else {
        list[list.indexOf(c)] = item;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('112 kaydı uygulamada ayrıca kırmızı kartta gösterilir.'),
        const SizedBox(height: 12),
        for (var i = 0; i < _cats.length; i++)
          Builder(builder: (context) {
            final cat = _cats[i] as Map<String, dynamic>;
            final contacts = (cat['contacts'] as List<dynamic>).cast<Map<String, dynamic>>();
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: Text(cat['title'] as String, style: Theme.of(context).textTheme.titleMedium),
                    trailing: RowActions(
                      onUp: i > 0 ? () => _apply(() => moveItem(_cats, i, -1)) : null,
                      onDown: i < _cats.length - 1 ? () => _apply(() => moveItem(_cats, i, 1)) : null,
                      onEdit: () => _editCategory(cat),
                      onDelete: () async {
                        if (await confirmDelete(context, 'Kategori (içindeki numaralarla)')) {
                          _apply(() => _cats.removeAt(i));
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  for (var j = 0; j < contacts.length; j++)
                    ListTile(
                      title: Text(contacts[j]['name'] as String),
                      subtitle: Text([
                        formatPhone(contacts[j]['phone'] as String),
                        if (contacts[j]['note'] != null) contacts[j]['note'] as String,
                      ].join(' · ')),
                      trailing: RowActions(
                        onUp: j > 0 ? () => _apply(() => moveItem(cat['contacts'] as List<dynamic>, j, -1)) : null,
                        onDown: j < contacts.length - 1
                            ? () => _apply(() => moveItem(cat['contacts'] as List<dynamic>, j, 1))
                            : null,
                        onEdit: () => _editContact(cat, contacts[j]),
                        onDelete: () async {
                          if (await confirmDelete(context, 'Numara')) {
                            _apply(() => (cat['contacts'] as List<dynamic>).removeAt(j));
                          }
                        },
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _editContact(cat),
                      icon: const Icon(Icons.add),
                      label: const Text('Numara ekle'),
                    ),
                  ),
                ],
              ),
            );
          }),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _editCategory(),
            icon: const Icon(Icons.add),
            label: const Text('Kategori ekle'),
          ),
        ),
      ],
    );
  }
}
