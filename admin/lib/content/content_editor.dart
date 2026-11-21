import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../api.dart';
import 'form_kit.dart';

typedef DataBuilder = Widget Function(BuildContext context, Map<String, dynamic> data, VoidCallback changed);

/// Bir içerik belgesini (content_docs) yükler, düzenletir ve kaydeder.
/// Belge panelden hiç kaydedilmemişse yayındaki kopyadan başlar.
class ContentEditor extends StatefulWidget {
  const ContentEditor({
    super.key,
    required this.api,
    required this.docId,
    required this.title,
    required this.builder,
    this.validate,
  });

  final Api api;
  final String docId;
  final String title;
  final DataBuilder builder;

  /// Kaydetmeden önce kontrol; hata metni ya da null.
  final String? Function(Map<String, dynamic> data)? validate;

  @override
  State<ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends State<ContentEditor> {
  Map<String, dynamic>? _doc;
  bool _fromPanel = false;
  bool _dirty = false;
  bool _saving = false;
  String? _loadError;
  late final _source = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _doc = null;
      _loadError = null;
      _dirty = false;
    });
    try {
      final saved = await widget.api.getContent(widget.docId);
      final doc = saved ?? await widget.api.getPublishedCopy(widget.docId);
      if (!mounted) return;
      setState(() {
        _doc = jsonDecode(jsonEncode(doc)) as Map<String, dynamic>;
        _fromPanel = saved != null;
        _source.text = (doc['source'] as String?) ?? '';
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  void _changed() => setState(() => _dirty = true);

  Future<void> _save() async {
    final doc = _doc!;
    final data = doc['data'] as Map<String, dynamic>;
    final problem = widget.validate?.call(data);
    if (problem != null) {
      _snack(problem);
      return;
    }
    setState(() => _saving = true);
    try {
      final source = _source.text.trim();
      doc
        ..['schemaVersion'] = 1
        ..['updatedAt'] = trNow();
      if (source.isEmpty) {
        doc.remove('source');
      } else {
        doc['source'] = source;
      }
      await widget.api.saveContent(widget.docId, doc);
      setState(() {
        _dirty = false;
        _fromPanel = true;
      });
      _snack('Kaydedildi. Uygulama bir sonraki açılışta / yenilemede yeni bilgiyi gösterir.');
    } catch (e) {
      _snack('Kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(tooltip: 'Yeniden yükle', onPressed: _saving ? null : _load, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: doc == null || !_dirty || _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Kaydediliyor…' : (_dirty ? 'Kaydet' : 'Kaydedildi')),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _loadError != null
          ? Center(child: Text(_loadError!))
          : doc == null
              ? const Center(child: CircularProgressIndicator())
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fromPanel
                                      ? 'Bu bilgiler panelden yönetiliyor.'
                                      : 'Henüz panelden kaydedilmedi: uygulamadaki kopya gösteriliyor. '
                                          'İlk kaydetmeden sonra uygulama bilgileri buradan alır.',
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('"ÖRNEK VERİ" uyarısını göster'),
                                  subtitle: const Text('Gerçek bilgileri girdiyseniz kapatın.'),
                                  value: doc['isSample'] as bool? ?? false,
                                  onChanged: (v) {
                                    doc['isSample'] = v;
                                    _changed();
                                  },
                                ),
                                TextField(
                                  controller: _source,
                                  onChanged: (_) => _changed(),
                                  decoration: const InputDecoration(
                                    labelText: 'Kaynak notu (isteğe bağlı, ör. "Erdek Belediyesi sitesi, Kasım 2026")',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        widget.builder(context, doc['data'] as Map<String, dynamic>, _changed),
                      ],
                    ),
                  ),
                ),
    );
  }
}

/// Liste öğesini yukarı/aşağı taşıma + düzenle/sil düğmeleri.
class RowActions extends StatelessWidget {
  const RowActions({super.key, required this.onEdit, required this.onDelete, this.onUp, this.onDown});

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onUp;
  final VoidCallback? onDown;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onUp != null || onDown != null) ...[
            IconButton(tooltip: 'Yukarı', onPressed: onUp, icon: const Icon(Icons.arrow_upward)),
            IconButton(tooltip: 'Aşağı', onPressed: onDown, icon: const Icon(Icons.arrow_downward)),
          ],
          IconButton(tooltip: 'Düzenle', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(tooltip: 'Sil', onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
        ],
      );
}

/// Listede [i]. öğeyi [delta] kadar kaydırır.
void moveItem(List<dynamic> list, int i, int delta) {
  final j = i + delta;
  if (j < 0 || j >= list.length) return;
  final item = list.removeAt(i);
  list.insert(j, item);
}
