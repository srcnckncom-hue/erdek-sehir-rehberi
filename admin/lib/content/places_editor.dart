import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../file_pick.dart';
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
  static const _maxPhotoBytes = 2 * 1024 * 1024;
  static const _maxPhotos = 10;

  List<dynamic> get _places => widget.data['places'] as List<dynamic>;

  /// Yükleniyor göstergesi için: fotoğraf eklenen yerin id'si.
  String? _uploadingFor;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<dynamic> _photosOf(Map<String, dynamic> place) =>
      place.putIfAbsent('photos', () => <dynamic>[]) as List<dynamic>;

  /// Fotoğraf seç → (isteğe bağlı) sahibi/kaynağı → Storage'a yükle → listeye ekle.
  /// Belgeye kaydetmek için yine üstteki "Kaydet" gerekir.
  Future<void> _addPhoto(Map<String, dynamic> place) async {
    if (_photosOf(place).length >= _maxPhotos) {
      _toast('Bir yere en fazla $_maxPhotos fotoğraf eklenebilir.');
      return;
    }
    final picked = await pickImage();
    if (picked == null) return;
    if (picked.bytes.length > _maxPhotoBytes) {
      _toast('Fotoğraf 2 MB\'tan büyük (${(picked.bytes.length / 1024).round()} KB). Küçültüp tekrar deneyin.');
      return;
    }
    if (!mounted) return;
    final v = await showFormDialog(
      context,
      title: 'Fotoğraf bilgisi',
      fields: const [
        FieldSpec(
          'credit',
          'Fotoğraf sahibi / kaynak (isteğe bağlı)',
          hint: 'Uygulamada "Fotoğraf: …" olarak görünür. Yalnızca kullanım hakkı olan fotoğrafları yükleyin.',
        ),
      ],
    );
    if (v == null) return;
    setState(() => _uploadingFor = place['id'] as String);
    try {
      final url = await widget.api.uploadContentImage(
        picked.bytes,
        contentType: picked.type,
        folder: 'places',
      );
      _apply(() => _photosOf(place).add(<String, dynamic>{
            'url': url,
            if (v['credit']!.isNotEmpty) 'credit': v['credit'],
          }));
      _toast('Fotoğraf yüklendi. Yayına almak için "Kaydet"e basın.');
    } catch (e) {
      _toast('Fotoğraf yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _uploadingFor = null);
    }
  }

  void _removePhoto(Map<String, dynamic> place, int index) {
    _apply(() {
      final photos = _photosOf(place)..removeAt(index);
      if (photos.isEmpty) place.remove('photos');
    });
  }

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
      // Fotoğraflar bu formda değil, kartın altında yönetilir; korunur.
      if ((p?['photos'] as List<dynamic>?)?.isNotEmpty ?? false) 'photos': p!['photos'],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
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
                _PhotoStrip(
                  photos: (places[i]['photos'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>(),
                  uploading: _uploadingFor == places[i]['id'],
                  onAdd: _uploadingFor == null ? () => _addPhoto(places[i]) : null,
                  onRemove: (index) async {
                    if (await confirmDelete(context, 'Fotoğraf')) _removePhoto(places[i], index);
                  },
                  onMakeCover: (index) => _apply(() => moveItem(_photosOf(places[i]), index, -index)),
                ),
              ],
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

/// Bir yerin fotoğrafları: küçük önizlemeler (ilki KAPAK), kapak yap, sil, ekle.
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.photos,
    required this.uploading,
    required this.onAdd,
    required this.onRemove,
    required this.onMakeCover,
  });

  final List<Map<String, dynamic>> photos;
  final bool uploading;
  final VoidCallback? onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onMakeCover;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < photos.length; i++)
            SizedBox(
              width: 128,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: scheme.surfaceContainerHighest,
                            child: Image.network(
                              photos[i]['url'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                          if (i == 0)
                            Positioned(
                              left: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Kapak',
                                  style: TextStyle(color: scheme.onPrimary, fontSize: 11),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (photos[i]['credit'] as String?) ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (i > 0)
                        IconButton(
                          tooltip: 'Kapak yap',
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          onPressed: () => onMakeCover(i),
                          icon: const Icon(Icons.star_outline),
                        ),
                      IconButton(
                        tooltip: 'Sil',
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: () => onRemove(i),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (uploading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(photos.isEmpty ? 'Fotoğraf ekle (en fazla 2 MB)' : 'Fotoğraf ekle'),
            ),
        ],
      ),
    );
  }
}
