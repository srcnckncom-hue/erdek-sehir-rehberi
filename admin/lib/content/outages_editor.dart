import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../screens/push_screen.dart';
import '../theme.dart';
import 'content_editor.dart';
import 'form_kit.dart';

/// Kesinti türleri (uygulamada karşılığı: OutageType).
const _types = {
  'su': 'Su kesintisi',
  'elektrik': 'Elektrik kesintisi',
  'dogalgaz': 'Doğal gaz kesintisi',
  'yol': 'Yol kapanması',
  'diger': 'Diğer',
};

const _typeIcons = {
  'su': Icons.water_drop_outlined,
  'elektrik': Icons.bolt_outlined,
  'dogalgaz': Icons.local_fire_department_outlined,
  'yol': Icons.signpost_outlined,
  'diger': Icons.warning_amber_outlined,
};

final _timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

String? _timeValidator(String v) => _timePattern.hasMatch(v) ? null : 'SS:DD biçiminde yazın, ör. 09:00';

/// Kesintiler: uygulamada Kesintiler sayfasında ve süren/24 saat içindeki
/// kesinti ana sayfada uyarı olarak görünür. Bitenler kendiliğinden kalkar.
/// "Mahallem"i seçen kullanıcıya başlamadan 1 saat önce hatırlatma gider.
class OutagesEditor extends StatelessWidget {
  const OutagesEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'outages',
        title: 'Kesintiler',
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
  List<dynamic> get _areas => widget.data.putIfAbsent('areas', () => <dynamic>[]) as List<dynamic>;
  List<dynamic> get _outages => widget.data.putIfAbsent('outages', () => <dynamic>[]) as List<dynamic>;

  void _apply(VoidCallback f) {
    setState(f);
    widget.changed();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _now() {
    final t = DateTime.now().toUtc().add(const Duration(hours: 3));
    String two(int v) => v.toString().padLeft(2, '0');
    return '${isoDate(t)}T${two(t.hour)}:${two(t.minute)}';
  }

  static String _end(Map<String, dynamic> o) {
    if (o['endsAt'] case final String e) return e;
    // Bitiş bilinmiyorsa uygulama 12 saat sonra kaldırır.
    final start = DateTime.parse(o['startsAt'] as String).add(const Duration(hours: 12));
    String two(int v) => v.toString().padLeft(2, '0');
    return '${isoDate(start)}T${two(start.hour)}:${two(start.minute)}';
  }

  static bool _isPast(Map<String, dynamic> o) => _end(o).compareTo(_now()) <= 0;

  void _sort() => _outages.sort(
        (a, b) => ((a as Map<String, dynamic>)['startsAt'] as String)
            .compareTo((b as Map<String, dynamic>)['startsAt'] as String),
      );

  static String _date(String? ts) => ts == null ? '' : ts.substring(0, 10);
  static String _time(String? ts) => ts == null ? '' : ts.substring(11, 16);

  Future<void> _editAreas() async {
    final v = await showFormDialog(
      context,
      title: 'Mahalle listesi',
      fields: [
        FieldSpec(
          'areas',
          'Mahalleler (her satıra bir tane)',
          kind: FieldKind.multiline,
          initial: _areas.join('\n'),
          hint: 'Kullanıcı "Mahallem"i bu listeden seçer. Kesintide yazdığınız mahalle adı bu listedekiyle aynı olmalı '
              '("Mah." / "Mahallesi" farkı önemli değil).',
        ),
      ],
    );
    if (v == null) return;
    _apply(() {
      _areas
        ..clear()
        ..addAll(splitLines(v['areas']!).toSet());
    });
  }

  Future<void> _edit([Map<String, dynamic>? o]) async {
    final areaHint = _areas.isEmpty
        ? 'Virgülle ayırın. Boş bırakılırsa "Tüm Erdek".'
        : 'Virgülle ayırın. Boşsa "Tüm Erdek". Listedekiler: ${_areas.join(', ')}';
    final v = await showFormDialog(
      context,
      title: o == null ? 'Kesinti ekle' : 'Kesintiyi düzenle',
      fields: [
        FieldSpec('type', 'Tür', kind: FieldKind.choice, options: _types, initial: (o?['type'] as String?) ?? 'su'),
        FieldSpec('areas', 'Etkilenen mahalleler', initial: (o?['areas'] as List<dynamic>?)?.join(', '), hint: areaHint),
        FieldSpec('startDate', 'Başlangıç günü', kind: FieldKind.date, required: true,
            initial: o == null ? null : _date(o['startsAt'] as String?)),
        FieldSpec('startTime', 'Başlangıç saati', required: true, initial: _time(o?['startsAt'] as String?),
            validator: _timeValidator, hint: 'Ör. 09:00'),
        FieldSpec('endDate', 'Bitiş günü (boşsa aynı gün)', kind: FieldKind.date,
            initial: o?['endsAt'] == null ? null : _date(o!['endsAt'] as String?)),
        FieldSpec('endTime', 'Bitiş saati (bilinmiyorsa boş: "giderilene kadar")',
            initial: _time(o?['endsAt'] as String?), validator: _timeValidator, hint: 'Ör. 15:00'),
        FieldSpec('reason', 'Sebep (isteğe bağlı)', initial: o?['reason'] as String?,
            hint: 'Ör. "Planlı bakım çalışması", "Ana boru arızası"'),
        FieldSpec('source', 'Kaynak (isteğe bağlı)', initial: o?['source'] as String?,
            hint: 'Ör. BASKİ, UEDAŞ, Erdek Belediyesi'),
        FieldSpec('note', 'Not (isteğe bağlı)', initial: o?['note'] as String?,
            hint: 'Ör. "Su depolarınızı önceden doldurun."'),
      ],
    );
    if (v == null) return;
    final startsAt = '${v['startDate']}T${v['startTime']}';
    String? endsAt;
    if (v['endTime']!.isNotEmpty) {
      endsAt = '${v['endDate']!.isEmpty ? v['startDate'] : v['endDate']}T${v['endTime']}';
      if (endsAt.compareTo(startsAt) <= 0) {
        _toast('Bitiş, başlangıçtan sonra olmalı (gece yarısını geçiyorsa bitiş gününü seçin).');
        return;
      }
    } else if (v['endDate']!.isNotEmpty) {
      _toast('Bitiş günü seçtiyseniz bitiş saatini de yazın.');
      return;
    }
    String? opt(String key) => v[key]!.isEmpty ? null : v[key];
    final item = <String, dynamic>{
      'id': o?['id'] ?? newId('kes'),
      'type': v['type'],
      'areas': v['areas']!.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList(),
      'startsAt': startsAt,
      'endsAt': ?endsAt,
      'reason': ?opt('reason'),
      'source': ?opt('source'),
      'note': ?opt('note'),
    };
    _apply(() {
      if (o == null) {
        _outages.add(item);
      } else {
        _outages[_outages.indexOf(o)] = item;
      }
      _sort();
    });
  }

  String _when(Map<String, dynamic> o) {
    final start = o['startsAt'] as String;
    final end = o['endsAt'] as String?;
    final from = '${trDateText(_date(start))} ${_time(start)}';
    if (end == null) return '$from – giderilene kadar';
    return _date(end) == _date(start) ? '$from – ${_time(end)}' : '$from – ${trDateText(_date(end))} ${_time(end)}';
  }

  String _areasText(Map<String, dynamic> o) {
    final areas = (o['areas'] as List<dynamic>? ?? const []).cast<String>();
    return areas.isEmpty ? 'Tüm Erdek' : areas.join(', ');
  }

  Future<void> _sendPush(Map<String, dynamic> o) async {
    String clip(String s, int max) => s.length <= max ? s : '${s.substring(0, max - 1)}…';
    final title = clip('${_types[o['type']] ?? 'Kesinti'}: ${_areasText(o)}', 80);
    final body = clip(
      [_when(o), if (o['reason'] != null) o['reason'], if (o['note'] != null) o['note']].join(' · '),
      240,
    );
    await confirmAndSendPush(context, widget.api, title: title, body: body, topic: 'kesintiler');
  }

  Future<void> _removePast() async {
    final past = _outages.cast<Map<String, dynamic>>().where(_isPast).length;
    if (past == 0) return;
    if (await confirmDelete(context, '$past geçmiş kesinti')) {
      _apply(() => _outages.removeWhere((o) => _isPast(o as Map<String, dynamic>)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _outages.cast<Map<String, dynamic>>();
    final pastCount = all.where(_isPast).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionTitle(
          'Mahalleler (${_areas.length})',
          subtitle: 'Kullanıcılar "Mahallem"i bu listeden seçer; o mahalledeki kesintiler öne çıkar ve hatırlatılır.',
          trailing: FilledButton.tonalIcon(
            onPressed: _editAreas,
            icon: const Icon(Icons.edit_location_alt_outlined),
            label: const Text('Listeyi düzenle'),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _areas.isEmpty
                ? const Text('Henüz mahalle eklenmedi. "Listeyi düzenle" ile ekleyin.')
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final a in _areas) Chip(label: Text(a as String))],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        AdminSectionTitle(
          'Kesintiler (${all.length})',
          subtitle: 'BASKİ / UEDAŞ / belediye duyurularından girin. Bitenler uygulamada kendiliğinden kalkar. '
              '✈ ile "Kesintiler" konusuna bildirim gönderebilirsiniz.',
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
                icon: const Icon(Icons.add),
                label: const Text('Kesinti ekle'),
              ),
            ],
          ),
        ),
        if (all.isEmpty)
          const Card(
            child: Padding(padding: EdgeInsets.all(24), child: Text('Kayıtlı kesinti yok.')),
          ),
        for (final o in all)
          Opacity(
            opacity: _isPast(o) ? 0.5 : 1,
            child: Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AdminColors.background,
                  child: Icon(_typeIcons[o['type']] ?? Icons.warning_amber_outlined, color: AdminColors.blue),
                ),
                title: Text(
                  '${_types[o['type']] ?? 'Kesinti'} · ${_areasText(o)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  [
                    _when(o),
                    if (o['reason'] != null) o['reason'] as String,
                    if (o['source'] != null) o['source'] as String,
                    if (_isPast(o)) 'BİTTİ',
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isPast(o))
                      IconButton(
                        tooltip: 'Bildirim olarak gönder (Kesintiler konusu)',
                        icon: const Icon(Icons.send_outlined),
                        onPressed: () => _sendPush(o),
                      ),
                    RowActions(
                      onEdit: () => _edit(o),
                      onDelete: () async {
                        if (await confirmDelete(context, 'Kesinti')) _apply(() => _outages.remove(o));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
