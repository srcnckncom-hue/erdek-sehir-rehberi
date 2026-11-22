import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../file_pick.dart';
import '../theme.dart';
import 'content_editor.dart';
import 'form_kit.dart';
import 'photo_strip.dart';

/// Etkinlik türleri (uygulamada karşılığı: EventCategory).
const _categories = {
  'konser': 'Konser',
  'festival': 'Festival / şenlik',
  'kultur': 'Kültür-sanat (tiyatro, sergi, söyleşi)',
  'spor': 'Spor',
  'cocuk': 'Çocuk',
  'pazar': 'Pazar / fuar',
  'diger': 'Diğer',
};

final _timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

String? _timeValidator(String v) => _timePattern.hasMatch(v) ? null : 'SS:DD biçiminde yazın, ör. 20:30';

/// Etkinlikler: uygulamada "Etkinlikler" sayfasında tarihe göre sıralı görünür,
/// bitenler kendiliğinden kalkar. Kullanıcı takvimine ekleyebilir, hatırlatma kurabilir.
class EventsEditor extends StatelessWidget {
  const EventsEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'events',
        title: 'Etkinlikler',
        validate: (data) {
          for (final e in (data['events'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>()) {
            final end = e['endDate'] as String?;
            if (end != null && end.compareTo(e['date'] as String) < 0) {
              return '"${e['title']}": bitiş günü başlangıçtan önce olamaz.';
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
  static const _maxPhotoBytes = 2 * 1024 * 1024;
  static const _maxPhotos = 6;

  String? _uploadingFor;

  List<dynamic> get _events => widget.data.putIfAbsent('events', () => <dynamic>[]) as List<dynamic>;

  void _apply(VoidCallback f) {
    setState(f);
    widget.changed();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _today() => isoDate(DateTime.now().toUtc().add(const Duration(hours: 3)));

  static bool _isPast(Map<String, dynamic> e) => ((e['endDate'] ?? e['date']) as String).compareTo(_today()) < 0;

  void _sort() => _events.sort((a, b) {
        final x = a as Map<String, dynamic>;
        final y = b as Map<String, dynamic>;
        final byDate = (x['date'] as String).compareTo(y['date'] as String);
        return byDate != 0 ? byDate : ((x['startTime'] ?? '') as String).compareTo((y['startTime'] ?? '') as String);
      });

  Future<void> _edit([Map<String, dynamic>? e]) async {
    final v = await showFormDialog(
      context,
      title: e == null ? 'Etkinlik ekle' : 'Etkinliği düzenle',
      fields: [
        FieldSpec('title', 'Etkinlik adı', initial: e?['title'] as String?, required: true,
            hint: 'Ör. "Erdek Kiraz Festivali"'),
        FieldSpec('category', 'Tür', kind: FieldKind.choice, options: _categories,
            initial: (e?['category'] as String?) ?? 'konser'),
        FieldSpec('date', 'Tarih (ilk gün)', kind: FieldKind.date, required: true, initial: e?['date'] as String?),
        FieldSpec('endDate', 'Son gün (birden çok gün sürüyorsa)', kind: FieldKind.date,
            initial: e?['endDate'] as String?),
        FieldSpec('startTime', 'Başlangıç saati (boşsa "tüm gün")', initial: e?['startTime'] as String?,
            validator: _timeValidator, hint: 'Ör. 20:30'),
        FieldSpec('endTime', 'Bitiş saati (isteğe bağlı)', initial: e?['endTime'] as String?,
            validator: _timeValidator, hint: 'Ör. 23:00'),
        FieldSpec('place', 'Yer', initial: e?['place'] as String?, hint: 'Ör. "Cumhuriyet Meydanı"'),
        FieldSpec('latitude', 'Enlem (isteğe bağlı)', initial: e?['latitude']?.toString(),
            validator: numberValidator(min: 40, max: 41), hint: 'Yol tarifi için. Ör. 40.3972'),
        FieldSpec('longitude', 'Boylam (isteğe bağlı)', initial: e?['longitude']?.toString(),
            validator: numberValidator(min: 27, max: 28.5)),
        FieldSpec('summary', 'Kısa tanım (isteğe bağlı)', initial: e?['summary'] as String?,
            hint: 'Ör. "Açık hava konseri, giriş ücretsiz"'),
        FieldSpec('description', 'Ayrıntılı açıklama (isteğe bağlı)', kind: FieldKind.multiline,
            initial: (e?['paragraphs'] as List<dynamic>?)?.join('\n\n'), hint: 'Paragrafları BOŞ SATIRLA ayırın.'),
        FieldSpec('organizer', 'Düzenleyen (isteğe bağlı)', initial: e?['organizer'] as String?,
            hint: 'Ör. "Erdek Belediyesi"'),
        FieldSpec('link', 'Ayrıntı / bilet adresi (isteğe bağlı)', initial: e?['link'] as String?,
            validator: httpsValidator, hint: 'https:// ile başlamalı. Ücretli etkinlikte bilet sayfası.'),
      ],
    );
    if (v == null) return;
    final lat = parseNumber(v['latitude']!);
    final lng = parseNumber(v['longitude']!);
    if ((lat == null) != (lng == null)) {
      _toast('Enlem ve boylam birlikte girilmeli.');
      return;
    }
    String? opt(String key) => v[key]!.isEmpty ? null : v[key];
    if (opt('endTime') != null && opt('startTime') == null) {
      _toast('Bitiş saati girdiyseniz başlangıç saatini de girin.');
      return;
    }
    final endDate = opt('endDate');
    if (endDate != null && endDate.compareTo(v['date']!) < 0) {
      _toast('Son gün, ilk günden önce olamaz.');
      return;
    }
    final paragraphs = splitParagraphs(v['description']!);
    final item = <String, dynamic>{
      'id': e?['id'] ?? newId('etk'),
      'title': v['title'],
      'category': v['category'],
      'date': v['date'],
      if (endDate != null && endDate != v['date']) 'endDate': endDate,
      'startTime': ?opt('startTime'),
      'endTime': ?opt('endTime'),
      'place': ?opt('place'),
      'latitude': ?lat,
      'longitude': ?lng,
      'summary': ?opt('summary'),
      if (paragraphs.isNotEmpty) 'paragraphs': paragraphs,
      'organizer': ?opt('organizer'),
      'link': ?opt('link'),
      if ((e?['photos'] as List<dynamic>?)?.isNotEmpty ?? false) 'photos': e!['photos'],
    };
    _apply(() {
      if (e == null) {
        _events.add(item);
      } else {
        _events[_events.indexOf(e)] = item;
      }
      _sort();
    });
  }

  List<dynamic> _photosOf(Map<String, dynamic> e) => e.putIfAbsent('photos', () => <dynamic>[]) as List<dynamic>;

  Future<void> _addPhoto(Map<String, dynamic> e) async {
    if (_photosOf(e).length >= _maxPhotos) {
      _toast('Bir etkinliğe en fazla $_maxPhotos fotoğraf eklenebilir.');
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
          hint: 'Yalnızca kullanım hakkı olan fotoğraf ya da afişleri yükleyin.',
        ),
      ],
    );
    if (v == null) return;
    setState(() => _uploadingFor = e['id'] as String);
    try {
      final url = await widget.api.uploadContentImage(picked.bytes, contentType: picked.type, folder: 'events');
      _apply(() => _photosOf(e).add(<String, dynamic>{
            'url': url,
            if (v['credit']!.isNotEmpty) 'credit': v['credit'],
          }));
      _toast('Fotoğraf yüklendi. Yayına almak için "Kaydet"e basın.');
    } catch (err) {
      _toast('Fotoğraf yüklenemedi: $err');
    } finally {
      if (mounted) setState(() => _uploadingFor = null);
    }
  }

  void _removePhoto(Map<String, dynamic> e, int index) => _apply(() {
        final photos = _photosOf(e)..removeAt(index);
        if (photos.isEmpty) e.remove('photos');
      });

  Future<void> _removePast() async {
    final past = _events.cast<Map<String, dynamic>>().where(_isPast).toList();
    if (past.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${past.length} geçmiş etkinlik silinsin mi?'),
        content: const Text('Uygulamada zaten görünmüyorlar. Silindikten sonra "Kaydet"e basın.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok == true) _apply(() => _events.removeWhere((e) => _isPast(e as Map<String, dynamic>)));
  }

  String _when(Map<String, dynamic> e) {
    final date = trDateText(e['date'] as String);
    final end = e['endDate'] == null ? '' : ' – ${trDateText(e['endDate'] as String)}';
    final time = switch ((e['startTime'], e['endTime'])) {
      (final String s, final String f) => ' · $s–$f',
      (final String s, _) => ' · $s',
      _ => ' · tüm gün',
    };
    return '$date$end$time';
  }

  @override
  Widget build(BuildContext context) {
    final all = _events.cast<Map<String, dynamic>>();
    final pastCount = all.where(_isPast).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionTitle(
          'Etkinlikler (${all.length})',
          subtitle: 'Tarihe göre sıralanır. Bitenler uygulamada kendiliğinden kalkar. '
              'Afiş/fotoğraf yalnızca kullanım hakkı varsa.',
          trailing: Wrap(
            spacing: 8,
            children: [
              if (pastCount > 0)
                OutlinedButton.icon(
                  onPressed: _removePast,
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: Text('Geçmişleri sil ($pastCount)'),
                ),
              FilledButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.event_outlined),
                label: const Text('Etkinlik ekle'),
              ),
            ],
          ),
        ),
        if (all.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Henüz etkinlik yok. "Etkinlik ekle" ile başlayın.'),
            ),
          ),
        for (final e in all)
          Opacity(
            opacity: _isPast(e) ? 0.5 : 1,
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    title: Text(e['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      [
                        _when(e),
                        _categories[e['category']] ?? '',
                        if (e['place'] != null) e['place'] as String,
                        if (_isPast(e)) 'GEÇTİ',
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: RowActions(
                      onEdit: () => _edit(e),
                      onDelete: () async {
                        if (await confirmDelete(context, 'Etkinlik')) _apply(() => _events.remove(e));
                      },
                    ),
                  ),
                  PhotoStrip(
                    photos: (e['photos'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>(),
                    uploading: _uploadingFor == e['id'],
                    onAdd: _uploadingFor == null ? () => _addPhoto(e) : null,
                    onRemove: (index) async {
                      if (await confirmDelete(context, 'Fotoğraf')) _removePhoto(e, index);
                    },
                    onMakeCover: (index) => _apply(() => moveItem(_photosOf(e), index, -index)),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'İpucu: Etkinliği ana sayfada öne çıkarmak için Hikâyeler\'e de ekleyebilir, '
          'Bildirim Gönder\'den "Etkinlikler" konusuyla duyurabilirsiniz.',
          style: TextStyle(fontSize: 12, color: AdminColors.muted),
        ),
      ],
    );
  }
}
