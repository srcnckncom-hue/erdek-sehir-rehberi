import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../file_pick.dart';
import '../theme.dart';
import 'content_editor.dart';
import 'form_kit.dart';
import 'photo_strip.dart';

/// Görünüm: ana sayfadaki hava durumu kartının arka plan fotoğrafı.
/// Birden fazla fotoğraf yüklenirse uygulama her gün sıradakini gösterir;
/// hiç yoksa uygulamayla gelen Erdek fotoğrafı görünür.
class AppearanceEditor extends StatelessWidget {
  const AppearanceEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'appearance',
        title: 'Görünüm',
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
  static const _max = 10;
  bool _uploading = false;

  List<dynamic> get _images => widget.data.putIfAbsent('heroImages', () => <dynamic>[]) as List<dynamic>;

  void _apply(VoidCallback f) {
    setState(f);
    widget.changed();
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _add() async {
    if (_images.length >= _max) {
      _toast('En fazla $_max fotoğraf eklenebilir.');
      return;
    }
    final picked = await pickImage();
    if (picked == null) return;
    if (picked.bytes.length > _maxBytes) {
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
          hint: 'Yalnızca kullanım hakkınız olan fotoğrafları yükleyin.',
        ),
      ],
    );
    if (v == null) return;
    setState(() => _uploading = true);
    try {
      final url = await widget.api.uploadContentImage(picked.bytes, contentType: picked.type, folder: 'appearance');
      _apply(() => _images.add(<String, dynamic>{
            'url': url,
            if (v['credit']!.isNotEmpty) 'credit': v['credit'],
          }));
      _toast('Yüklendi. Uygulamada görünmesi için "Kaydet"e basın.');
    } catch (e) {
      _toast('Yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _images.cast<Map<String, dynamic>>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminSectionTitle(
          'Ana sayfa arka plan fotoğrafı',
          subtitle: 'Hava durumu, selamlama ve arama kutusunun arkasında görünür. '
              'Yatay, en az 1600×1000 piksel, 2 MB\'tan küçük olmalı. Üstüne yazı geldiği için '
              'gökyüzü/deniz gibi sade fotoğraflar en iyi sonucu verir.',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    images.isEmpty
                        ? 'Şu an uygulamayla gelen Erdek fotoğrafı gösteriliyor.'
                        : images.length == 1
                            ? 'Bu fotoğraf her gün gösterilir.'
                            : '${images.length} fotoğraf her gün sırayla değişir.',
                    style: const TextStyle(color: AdminColors.muted),
                  ),
                ),
                if (images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _Preview(url: images.first['url'] as String),
                  ),
                PhotoStrip(
                  photos: images,
                  uploading: _uploading,
                  onAdd: _uploading ? null : _add,
                  onRemove: (index) async {
                    if (await confirmDelete(context, 'Fotoğraf')) _apply(() => _images.removeAt(index));
                  },
                  onMakeCover: (index) => _apply(() => moveItem(_images, index, -index)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Uygulamadaki ana sayfa üst kısmına benzer önizleme.
class _Preview extends StatelessWidget {
  const _Preview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            child: AspectRatio(
              aspectRatio: 390 / 300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(url, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x8C001A33), Color(0x1A001A33), Color(0x99001A33)],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('İyi günler', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                        Text('Erdek · Pazar', style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 8),
                        Text('16°', style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w300)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
