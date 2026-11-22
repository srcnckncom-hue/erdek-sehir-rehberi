import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../file_pick.dart';
import '../theme.dart';
import 'content_editor.dart';
import 'form_kit.dart';
import 'photo_strip.dart';

const _types = {
  'yuruyus': 'Yürüyüş',
  'bisiklet': 'Bisiklet',
  'tekne': 'Tekne / ada turu',
  'arac': 'Araçla gezi',
  'tarih': 'Tarih / kültür turu',
};

const _difficulties = {'': '—', 'kolay': 'Kolay', 'orta': 'Orta', 'zor': 'Zor'};

/// "Ad | 40.39, 27.79 | not" satırını durağa çevirir. Koordinat ve not isteğe bağlı.
/// Hatalıysa hata metni döner.
(Map<String, dynamic>?, String?) parseStopLine(String line) {
  final parts = line.split('|').map((p) => p.trim()).toList();
  final name = parts.first;
  if (name.isEmpty) return (null, '"$line": durak adı boş');
  final stop = <String, dynamic>{'name': name};
  if (parts.length > 1 && parts[1].isNotEmpty) {
    final ll = parts[1].split(',').map((x) => double.tryParse(x.trim())).toList();
    if (ll.length != 2 || ll.contains(null) || ll[0]! < 40 || ll[0]! > 41 || ll[1]! < 27 || ll[1]! > 28.5) {
      return (null, '"$name": koordinat "enlem, boylam" olmalı (ör. 40.3897, 27.8902)');
    }
    stop['latitude'] = ll[0];
    stop['longitude'] = ll[1];
  }
  if (parts.length > 2 && parts.sublist(2).join(' | ').isNotEmpty) stop['note'] = parts.sublist(2).join(' | ');
  return (stop, null);
}

String _stopLine(Map<String, dynamic> s) => [
      s['name'],
      if (s['latitude'] != null) '${s['latitude']}, ${s['longitude']}' else if (s['note'] != null) '',
      ?s['note'],
    ].join(' | ');

/// Gezi rotaları: yürüyüş, bisiklet, tekne turu… Uygulamada harita (duraklar +
/// çizgi), Google Haritalar'da yol tarifi ve paylaşma.
class TripsEditor extends StatelessWidget {
  const TripsEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'trips',
        title: 'Gezi Rotaları',
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
  static const _maxPhotos = 6;
  String? _uploadingFor;

  List<dynamic> get _trips => widget.data.putIfAbsent('trips', () => <dynamic>[]) as List<dynamic>;

  void _apply(VoidCallback f) {
    setState(f);
    widget.changed();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit([Map<String, dynamic>? t]) async {
    final v = await showFormDialog(
      context,
      title: t == null ? 'Rota ekle' : 'Rotayı düzenle',
      fields: [
        FieldSpec('title', 'Rota adı', initial: t?['title'] as String?, required: true,
            hint: 'Ör. "Kapıdağ Zirve Yürüyüşü"'),
        FieldSpec('type', 'Tür', kind: FieldKind.choice, options: _types, initial: (t?['type'] as String?) ?? 'yuruyus'),
        FieldSpec('difficulty', 'Zorluk', kind: FieldKind.choice, options: _difficulties,
            initial: (t?['difficulty'] as String?) ?? ''),
        FieldSpec('distanceKm', 'Mesafe km (isteğe bağlı)', initial: t?['distanceKm']?.toString(),
            validator: numberValidator(min: 0.1, max: 500), hint: 'Ör. 6,5'),
        FieldSpec('durationMin', 'Süre, dakika (isteğe bağlı)', initial: t?['durationMin']?.toString(),
            validator: numberValidator(min: 5, max: 1440), hint: 'Ör. 150 (2 sa 30 dk)'),
        FieldSpec('season', 'En uygun dönem (isteğe bağlı)', initial: t?['season'] as String?,
            hint: 'Ör. "Nisan–Haziran, Eylül–Ekim"'),
        FieldSpec('summary', 'Kısa tanım (listede görünür)', kind: FieldKind.multiline,
            initial: t?['summary'] as String?, required: true),
        FieldSpec('paragraphs', 'Ayrıntılı anlatım (isteğe bağlı)', kind: FieldKind.multiline,
            initial: (t?['paragraphs'] as List<dynamic>?)?.join('\n\n'), hint: 'Paragrafları BOŞ SATIRLA ayırın.'),
        FieldSpec('stops', 'Duraklar (her satıra bir durak, sırayla)', kind: FieldKind.multiline,
            initial: (t?['stops'] as List<dynamic>?)?.cast<Map<String, dynamic>>().map(_stopLine).join('\n'),
            hint: 'Biçim: Ad | enlem, boylam | not   — koordinat ve not isteğe bağlı.\n'
                'Ör: Kyzikos Antik Kenti | 40.3897, 27.8902 | Hadrian Tapınağı kalıntıları'),
        FieldSpec('path', 'Rota çizgisi (isteğe bağlı, her satıra "enlem, boylam")', kind: FieldKind.multiline,
            initial: (t?['path'] as List<dynamic>?)?.map((p) => (p as List<dynamic>).join(', ')).join('\n'),
            hint: 'Boşsa duraklar sırayla birleştirilir. Patika gerçek izini çizmek için noktaları buraya yapıştırın.'),
        FieldSpec('tips', 'İpuçları (isteğe bağlı, her satıra bir)', kind: FieldKind.multiline,
            initial: (t?['tips'] as List<dynamic>?)?.join('\n'), hint: 'Ör. "Yanınıza su alın", "Yağmurdan sonra patika kaygandır"'),
      ],
    );
    if (v == null || !mounted) return;
    final stops = <Map<String, dynamic>>[];
    for (final line in splitLines(v['stops']!)) {
      final (stop, error) = parseStopLine(line);
      if (error != null) {
        _toast(error);
        return;
      }
      stops.add(stop!);
    }
    final path = <List<double>>[];
    for (final line in splitLines(v['path']!)) {
      final ll = line.split(',').map((x) => double.tryParse(x.trim())).toList();
      if (ll.length != 2 || ll.contains(null)) {
        _toast('Rota çizgisinde hatalı satır: "$line" (enlem, boylam olmalı)');
        return;
      }
      path.add([ll[0]!, ll[1]!]);
    }
    String? opt(String key) => v[key]!.isEmpty ? null : v[key];
    final paragraphs = splitParagraphs(v['paragraphs']!);
    final tips = splitLines(v['tips']!);
    final km = parseNumber(v['distanceKm']!);
    final minutes = parseNumber(v['durationMin']!);
    final item = <String, dynamic>{
      'id': t?['id'] ?? newId('rota'),
      'title': v['title'],
      'type': v['type'],
      'summary': v['summary'],
      'difficulty': ?opt('difficulty'),
      'distanceKm': ?km,
      'durationMin': ?minutes?.round(),
      'season': ?opt('season'),
      if (paragraphs.isNotEmpty) 'paragraphs': paragraphs,
      if (tips.isNotEmpty) 'tips': tips,
      if (stops.isNotEmpty) 'stops': stops,
      if (path.length > 1) 'path': path,
      if ((t?['photos'] as List<dynamic>?)?.isNotEmpty ?? false) 'photos': t!['photos'],
    };
    _apply(() {
      if (t == null) {
        _trips.add(item);
      } else {
        _trips[_trips.indexOf(t)] = item;
      }
    });
  }

  List<dynamic> _photosOf(Map<String, dynamic> t) => t.putIfAbsent('photos', () => <dynamic>[]) as List<dynamic>;

  Future<void> _addPhoto(Map<String, dynamic> t) async {
    if (_photosOf(t).length >= _maxPhotos) {
      _toast('Bir rotaya en fazla $_maxPhotos fotoğraf eklenebilir.');
      return;
    }
    final picked = await pickImage();
    if (picked == null) return;
    if (picked.bytes.length > _maxPhotoBytes) {
      _toast('Fotoğraf 2 MB\'tan büyük. Küçültüp tekrar deneyin.');
      return;
    }
    if (!mounted) return;
    final v = await showFormDialog(
      context,
      title: 'Fotoğraf bilgisi',
      fields: const [
        FieldSpec('credit', 'Fotoğraf sahibi / kaynak (isteğe bağlı)',
            hint: 'Yalnızca kullanım hakkı olan fotoğrafları yükleyin.'),
      ],
    );
    if (v == null) return;
    setState(() => _uploadingFor = t['id'] as String);
    try {
      final url = await widget.api.uploadContentImage(picked.bytes, contentType: picked.type, folder: 'trips');
      _apply(() => _photosOf(t).add(<String, dynamic>{'url': url, if (v['credit']!.isNotEmpty) 'credit': v['credit']}));
      _toast('Fotoğraf yüklendi. Yayına almak için "Kaydet"e basın.');
    } catch (e) {
      _toast('Fotoğraf yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _uploadingFor = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _trips.cast<Map<String, dynamic>>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionTitle(
          'Gezi Rotaları (${all.length})',
          subtitle: 'Bu sırayla listelenir. Durakların koordinatı varsa uygulamada haritada numaralı görünür.',
          trailing: FilledButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add_road),
            label: const Text('Rota ekle'),
          ),
        ),
        if (all.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Henüz rota eklenmedi.'))),
        for (var i = 0; i < all.length; i++)
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                  leading: const CircleAvatar(
                    backgroundColor: AdminColors.background,
                    child: Icon(Icons.route_outlined, color: AdminColors.blue),
                  ),
                  title: Text(all[i]['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    [
                      _types[all[i]['type']] ?? '',
                      if (all[i]['distanceKm'] != null) '${all[i]['distanceKm']} km',
                      '${(all[i]['stops'] as List<dynamic>?)?.length ?? 0} durak',
                    ].join(' · '),
                  ),
                  trailing: RowActions(
                    onUp: i > 0 ? () => _apply(() => moveItem(_trips, i, -1)) : null,
                    onDown: i < all.length - 1 ? () => _apply(() => moveItem(_trips, i, 1)) : null,
                    onEdit: () => _edit(all[i]),
                    onDelete: () async {
                      if (await confirmDelete(context, 'Rota')) _apply(() => _trips.removeAt(i));
                    },
                  ),
                ),
                PhotoStrip(
                  photos: (all[i]['photos'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>(),
                  uploading: _uploadingFor == all[i]['id'],
                  onAdd: _uploadingFor == null ? () => _addPhoto(all[i]) : null,
                  onRemove: (index) async {
                    if (await confirmDelete(context, 'Fotoğraf')) {
                      _apply(() {
                        final photos = _photosOf(all[i])..removeAt(index);
                        if (photos.isEmpty) all[i].remove('photos');
                      });
                    }
                  },
                  onMakeCover: (index) => _apply(() => moveItem(_photosOf(all[i]), index, -index)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
