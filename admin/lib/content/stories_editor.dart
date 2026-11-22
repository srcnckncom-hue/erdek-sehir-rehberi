import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../file_pick.dart';
import '../theme.dart';
import 'content_editor.dart';
import 'form_kit.dart';

/// Ana sayfa hikâyeleri (Instagram hikâyesi gibi): yuvarlak kapak + başlık,
/// içinde sırayla gösterilen fotoğraflar (isteğe bağlı yazı ve bağlantı).
class StoriesEditor extends StatelessWidget {
  const StoriesEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'stories',
        title: 'Hikâyeler',
        validate: (data) {
          for (final s in (data['stories'] as List<dynamic>).cast<Map<String, dynamic>>()) {
            if ((s['cover'] as String?)?.isEmpty ?? true) return '"${s['title']}" için kapak fotoğrafı yükleyin.';
            if ((s['slides'] as List<dynamic>? ?? const []).isEmpty) {
              return '"${s['title']}" hikâyesine en az bir fotoğraf ekleyin.';
            }
          }
          return null;
        },
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
  static const _maxBytes = 2 * 1024 * 1024;
  static const _maxSlides = 15;

  /// Yükleme süren hikâye kimliği (kapak ya da sayfa).
  String? _uploading;

  List<dynamic> get _stories => widget.data.putIfAbsent('stories', () => <dynamic>[]) as List<dynamic>;

  void _apply(VoidCallback f) {
    setState(f);
    widget.changed();
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  /// Fotoğraf seç → boyut kontrolü → yükle → adres.
  Future<String?> _pickAndUpload(String storyId) async {
    final picked = await pickImage();
    if (picked == null) return null;
    if (picked.bytes.length > _maxBytes) {
      _toast('Fotoğraf 2 MB\'tan büyük (${(picked.bytes.length / 1024).round()} KB). Küçültüp tekrar deneyin.');
      return null;
    }
    setState(() => _uploading = storyId);
    try {
      return await widget.api.uploadContentImage(picked.bytes, contentType: picked.type, folder: 'stories');
    } catch (e) {
      _toast('Fotoğraf yüklenemedi: $e');
      return null;
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  static String? _toStart(String date) => date.isEmpty ? null : '${date}T00:00:00+03:00';

  /// Bitiş tarihi dahil: ertesi gün 00:00'da yayından kalkar.
  static String? _toEnd(String date) {
    if (date.isEmpty) return null;
    final d = DateTime.parse(date).add(const Duration(days: 1));
    return '${isoDate(d)}T00:00:00+03:00';
  }

  static String _endDateText(String? endsAt) {
    final part = datePart(endsAt);
    if (part.isEmpty) return '';
    return isoDate(DateTime.parse(part).subtract(const Duration(days: 1)));
  }

  Future<void> _edit([Map<String, dynamic>? s]) async {
    final v = await showFormDialog(
      context,
      title: s == null ? 'Hikâye ekle' : 'Hikâyeyi düzenle',
      fields: [
        FieldSpec(
          'title',
          'Başlık (yuvarlağın altında görünür, en fazla 24 harf)',
          initial: s?['title'] as String?,
          required: true,
          validator: (v) => v.length > 24 ? 'En fazla 24 harf' : null,
          hint: 'Ör. Kampanyalar',
        ),
        FieldSpec(
          'startsAt',
          'Yayın başlangıcı (isteğe bağlı)',
          kind: FieldKind.date,
          initial: datePart(s?['startsAt'] as String?),
        ),
        FieldSpec(
          'endsAt',
          'Son gün (isteğe bağlı; o gün bitince kalkar)',
          kind: FieldKind.date,
          initial: _endDateText(s?['endsAt'] as String?),
        ),
      ],
    );
    if (v == null) return;
    final start = _toStart(v['startsAt']!);
    final end = _toEnd(v['endsAt']!);
    if (start != null && end != null && start.compareTo(end) >= 0) {
      _toast('Son gün, başlangıçtan önce olamaz.');
      return;
    }
    _apply(() {
      final target = s ?? <String, dynamic>{'id': newId('hk'), 'cover': '', 'slides': <dynamic>[]};
      target['title'] = v['title'];
      if (start == null) {
        target.remove('startsAt');
      } else {
        target['startsAt'] = start;
      }
      if (end == null) {
        target.remove('endsAt');
      } else {
        target['endsAt'] = end;
      }
      if (s == null) _stories.add(target);
    });
    if (s == null) _toast('Şimdi kapak fotoğrafı ve hikâye fotoğraflarını ekleyin, sonra "Kaydet".');
  }

  Future<void> _setCover(Map<String, dynamic> s) async {
    final url = await _pickAndUpload(s['id'] as String);
    if (url != null) _apply(() => s['cover'] = url);
  }

  List<dynamic> _slidesOf(Map<String, dynamic> s) => s.putIfAbsent('slides', () => <dynamic>[]) as List<dynamic>;

  Future<void> _addSlide(Map<String, dynamic> s) async {
    if (_slidesOf(s).length >= _maxSlides) {
      _toast('Bir hikâyede en fazla $_maxSlides fotoğraf olabilir.');
      return;
    }
    final url = await _pickAndUpload(s['id'] as String);
    if (url == null || !mounted) return;
    final v = await _slideForm();
    _apply(() => _slidesOf(s).add(<String, dynamic>{'url': url, ...?v}));
  }

  /// Yazı + bağlantı (hepsi isteğe bağlı). Vazgeçilirse boş.
  Future<Map<String, dynamic>?> _slideForm([Map<String, dynamic>? slide]) async {
    final v = await showFormDialog(
      context,
      title: 'Fotoğraf yazısı ve bağlantısı',
      fields: [
        FieldSpec('caption', 'Yazı (isteğe bağlı)', kind: FieldKind.multiline, initial: slide?['caption'] as String?),
        FieldSpec(
          'link',
          'Bağlantı (isteğe bağlı)',
          initial: slide?['link'] as String?,
          validator: (v) => v.isEmpty ? null : httpsValidator(v),
          hint: 'https:// ile başlamalı',
        ),
        FieldSpec('linkLabel', 'Düğme yazısı (isteğe bağlı)', initial: slide?['linkLabel'] as String?, hint: 'Ör. Ayrıntılar'),
      ],
    );
    if (v == null) return null;
    return {
      if (v['caption']!.isNotEmpty) 'caption': v['caption'],
      if (v['link']!.isNotEmpty) 'link': v['link'],
      if (v['link']!.isNotEmpty && v['linkLabel']!.isNotEmpty) 'linkLabel': v['linkLabel'],
    };
  }

  Future<void> _editSlide(Map<String, dynamic> s, int i) async {
    final slide = _slidesOf(s)[i] as Map<String, dynamic>;
    final v = await _slideForm(slide);
    if (v == null) return;
    _apply(() => _slidesOf(s)[i] = <String, dynamic>{'url': slide['url'], ...v});
  }

  String _status(Map<String, dynamic> s) {
    final now = DateTime.now();
    final start = DateTime.tryParse(s['startsAt'] as String? ?? '');
    final end = DateTime.tryParse(s['endsAt'] as String? ?? '');
    if (end != null && !now.isBefore(end)) return 'Süresi bitti';
    if (start != null && now.isBefore(start)) return '${trDateText(datePart(s['startsAt'] as String))} tarihinde başlar';
    if (end != null) return 'Yayında · ${trDateText(_endDateText(s['endsAt'] as String))} sonuna kadar';
    return 'Yayında';
  }

  @override
  Widget build(BuildContext context) {
    final stories = _stories.cast<Map<String, dynamic>>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionTitle(
          'Hikâyeler (${stories.length})',
          subtitle: 'Uygulamada Hızlı İşlemler\'in üstünde yuvarlak olarak, bu sırayla görünür. '
              'Fotoğraflar dikey (9:16) olursa ekranı tam doldurur.',
          trailing: FilledButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Hikâye ekle'),
          ),
        ),
        if (stories.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Uygulamada görünüm', style: TextStyle(fontWeight: FontWeight.w600, color: AdminColors.muted)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 104,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [for (final s in stories) _Bubble(story: s)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (stories.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Henüz hikâye yok. "Hikâye ekle" ile başlayın.'),
            ),
          ),
        for (var i = 0; i < stories.length; i++)
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                  leading: _Bubble(story: stories[i], size: 48, showTitle: false),
                  title: Text(stories[i]['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${_status(stories[i])} · ${_slidesOf(stories[i]).length} fotoğraf'),
                  trailing: RowActions(
                    onUp: i > 0 ? () => _apply(() => moveItem(_stories, i, -1)) : null,
                    onDown: i < stories.length - 1 ? () => _apply(() => moveItem(_stories, i, 1)) : null,
                    onEdit: () => _edit(stories[i]),
                    onDelete: () async {
                      if (await confirmDelete(context, 'Hikâye')) _apply(() => _stories.removeAt(i));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _uploading == null ? () => _setCover(stories[i]) : null,
                        icon: const Icon(Icons.account_circle_outlined),
                        label: Text((stories[i]['cover'] as String?)?.isEmpty ?? true ? 'Kapak yükle' : 'Kapağı değiştir'),
                      ),
                      for (var j = 0; j < _slidesOf(stories[i]).length; j++)
                        _SlideThumb(
                          slide: _slidesOf(stories[i])[j] as Map<String, dynamic>,
                          index: j,
                          onEdit: () => _editSlide(stories[i], j),
                          onLeft: j > 0 ? () => _apply(() => moveItem(_slidesOf(stories[i]), j, -1)) : null,
                          onDelete: () async {
                            if (await confirmDelete(context, 'Fotoğraf')) {
                              _apply(() => _slidesOf(stories[i]).removeAt(j));
                            }
                          },
                        ),
                      if (_uploading == stories[i]['id'])
                        const SizedBox.square(dimension: 32, child: CircularProgressIndicator(strokeWidth: 3))
                      else
                        FilledButton.tonalIcon(
                          onPressed: _uploading == null ? () => _addSlide(stories[i]) : null,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Fotoğraf ekle'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Uygulamadaki gibi halkalı yuvarlak + başlık.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.story, this.size = 68, this.showTitle = true});

  final Map<String, dynamic> story;
  final double size;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final cover = story['cover'] as String? ?? '';
    final circle = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFFF9A825), Color(0xFFED681B), Color(0xFFD81B60), Color(0xFF8E24AA)],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: ClipOval(
          child: cover.isEmpty
              ? const ColoredBox(color: AdminColors.background, child: Icon(Icons.image_outlined, color: AdminColors.muted))
              : Image.network(cover, fit: BoxFit.cover),
        ),
      ),
    );
    if (!showTitle) return circle;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: size + 4,
        child: Column(
          children: [
            circle,
            const SizedBox(height: 6),
            Text(
              story['title'] as String? ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideThumb extends StatelessWidget {
  const _SlideThumb({
    required this.slide,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    this.onLeft,
  });

  final Map<String, dynamic> slide;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onLeft;

  @override
  Widget build(BuildContext context) {
    final hasText = slide['caption'] != null || slide['link'] != null;
    return SizedBox(
      width: 84,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(slide['url'] as String, fit: BoxFit.cover),
                  Positioned(
                    left: 4,
                    top: 4,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.black54,
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                  if (hasText)
                    const Positioned(
                      right: 4,
                      top: 4,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.notes, size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Öne al',
                onPressed: onLeft,
                icon: const Icon(Icons.chevron_left, size: 18),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Yazı / bağlantı',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Sil',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
