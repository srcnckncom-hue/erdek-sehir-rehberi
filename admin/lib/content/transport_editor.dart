import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../api.dart';
import 'content_editor.dart';
import 'form_kit.dart';

const _modes = {'ferry': 'Feribot', 'bus': 'Şehirlerarası otobüs', 'city': 'Şehir içi otobüs'};
const _directions = {'outbound': 'Gidiş (Erdek\'ten)', 'inbound': 'Dönüş (Erdek\'e)'};
const _dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

/// Ulaşım: hatlar → tarifeler (tarih aralığı) → sefer saatleri.
class TransportEditor extends StatelessWidget {
  const TransportEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'transport',
        title: 'Ulaşım',
        validate: (data) {
          final routes = (data['routes'] as List<dynamic>).cast<Map<String, dynamic>>();
          if (routes.isEmpty) return 'En az bir hat olmalı.';
          for (final r in routes) {
            final tts = (r['timetables'] as List<dynamic>).cast<Map<String, dynamic>>();
            if (tts.isEmpty) return '"${r['title']}" hattında en az bir tarife olmalı.';
            for (final t in tts) {
              if ((t['validFrom'] as String).compareTo(t['validTo'] as String) > 0) {
                return '"${r['title']}" / "${t['name']}": başlangıç tarihi bitişten sonra.';
              }
            }
          }
          return null;
        },
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
  String _mode = 'ferry';

  List<dynamic> get _routes => widget.data['routes'] as List<dynamic>;

  void _apply(VoidCallback f) {
    setState(f);
    widget.changed();
  }

  Future<void> _editRoute([Map<String, dynamic>? r]) async {
    final v = await showFormDialog(
      context,
      title: r == null ? 'Hat ekle' : 'Hattı düzenle',
      fields: [
        FieldSpec('mode', 'Tür', kind: FieldKind.choice, options: _modes, initial: (r?['mode'] as String?) ?? _mode),
        FieldSpec('direction', 'Yön', kind: FieldKind.choice, options: _directions, initial: r?['direction'] as String?),
        FieldSpec('title', 'Hat adı (ör. Erdek → Avşa, Hat 3: Merkez → Ocaklar)', initial: r?['title'] as String?, required: true),
        FieldSpec('from', 'Kalkış yeri', initial: r?['from'] as String?, required: true),
        FieldSpec('to', 'Varış yeri', initial: r?['to'] as String?, required: true),
        FieldSpec('operator', 'İşletme (isteğe bağlı)', initial: r?['operator'] as String?),
        FieldSpec('phone', 'İşletme telefonu (isteğe bağlı)',
            initial: r?['phone'] == null ? null : formatPhone(r!['phone'] as String),
            validator: phoneValidator, keyboard: TextInputType.phone),
        FieldSpec('note', 'Not (isteğe bağlı)', kind: FieldKind.multiline, initial: r?['note'] as String?),
        FieldSpec('stops', 'Duraklar (isteğe bağlı, her satıra bir durak, sırasıyla)',
            kind: FieldKind.multiline, initial: (r?['stops'] as List<dynamic>?)?.join('\n')),
        FieldSpec('isSample', 'Bu hat ÖRNEK mi? (uygulamada uyarı gösterir)',
            kind: FieldKind.choice, options: const {'false': 'Hayır, gerçek bilgi', 'true': 'Evet, örnek'},
            initial: '${r?['isSample'] ?? false}'),
      ],
    );
    if (v == null) return;
    final item = <String, dynamic>{
      'id': r?['id'] ?? newId('hat'),
      'mode': v['mode'],
      'direction': v['direction'],
      'title': v['title'],
      'from': v['from'],
      'to': v['to'],
      if (v['operator']!.isNotEmpty) 'operator': v['operator'],
      if (v['phone']!.isNotEmpty) 'phone': normalizePhone(v['phone']!),
      if (v['note']!.isNotEmpty) 'note': v['note'],
      if (v['isSample'] == 'true') 'isSample': true,
      if (v['stops']!.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() case final stops
          when stops.isNotEmpty)
        'stops': stops,
      'timetables': r?['timetables'] ??
          [
            {'name': 'Tarife', 'validFrom': isoDate(DateTime.now()), 'validTo': '${DateTime.now().year + 1}-12-31', 'departures': <dynamic>[]},
          ],
    };
    _apply(() {
      if (r == null) {
        _routes.add(item);
        _mode = item['mode'] as String;
      } else {
        _routes[_routes.indexOf(r)] = item;
      }
    });
  }

  Future<void> _editTimetable(Map<String, dynamic> route, [Map<String, dynamic>? t]) async {
    final v = await showFormDialog(
      context,
      title: t == null ? 'Tarife ekle' : 'Tarifeyi düzenle',
      fields: [
        FieldSpec('name', 'Tarife adı (ör. Kış tarifesi)', initial: t?['name'] as String?, required: true),
        FieldSpec('validFrom', 'Geçerlilik başlangıcı', kind: FieldKind.date, initial: t?['validFrom'] as String?, required: true),
        FieldSpec('validTo', 'Geçerlilik bitişi', kind: FieldKind.date, initial: t?['validTo'] as String?, required: true),
      ],
    );
    if (v == null) return;
    if (v['validFrom']!.compareTo(v['validTo']!) > 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Başlangıç bitişten sonra olamaz.')));
      }
      return;
    }
    _apply(() {
      final list = route['timetables'] as List<dynamic>;
      if (t == null) {
        list.add({'name': v['name'], 'validFrom': v['validFrom'], 'validTo': v['validTo'], 'departures': <dynamic>[]});
      } else {
        t
          ..['name'] = v['name']
          ..['validFrom'] = v['validFrom']
          ..['validTo'] = v['validTo'];
      }
    });
  }

  Future<void> _editDepartures(Map<String, dynamic> route, Map<String, dynamic> t) async {
    final copy = (jsonDecode(jsonEncode(t['departures'])) as List<dynamic>).cast<Map<String, dynamic>>();
    final result = await Navigator.of(context).push<List<Map<String, dynamic>>>(
      MaterialPageRoute(
        builder: (_) => _DeparturesPage(title: '${route['title']} · ${t['name']}', departures: copy),
      ),
    );
    if (result != null) _apply(() => t['departures'] = result);
  }

  @override
  Widget build(BuildContext context) {
    final routes = _routes.cast<Map<String, dynamic>>();
    final visible = [for (var i = 0; i < routes.length; i++) if (routes[i]['mode'] == _mode) i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<String>(
          segments: [for (final e in _modes.entries) ButtonSegment(value: e.key, label: Text(e.value))],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const SizedBox(height: 12),
        const Text('Her yön ayrı hattır (ör. "Erdek → Avşa" ve "Avşa → Erdek"). '
            'Bir sefer belirli günlerde varsa günlerini seçin; gün seçilmezse her gün sayılır.'),
        const SizedBox(height: 12),
        for (final i in visible)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Text(
                    '${routes[i]['title']}${routes[i]['isSample'] == true ? '  (ÖRNEK)' : ''}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text([
                    _directions[routes[i]['direction']] ?? '',
                    '${routes[i]['from']} → ${routes[i]['to']}',
                    if (routes[i]['operator'] != null) routes[i]['operator'],
                  ].join(' · ')),
                  trailing: RowActions(
                    onUp: i > 0 ? () => _apply(() => moveItem(_routes, i, -1)) : null,
                    onDown: i < routes.length - 1 ? () => _apply(() => moveItem(_routes, i, 1)) : null,
                    onEdit: () => _editRoute(routes[i]),
                    onDelete: () async {
                      if (await confirmDelete(context, 'Hat (tüm tarifeleriyle)')) _apply(() => _routes.removeAt(i));
                    },
                  ),
                ),
                for (final t in (routes[i]['timetables'] as List<dynamic>).cast<Map<String, dynamic>>())
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text('${t['name']} · ${trDateText(t['validFrom'] as String)} – ${trDateText(t['validTo'] as String)}'),
                    subtitle: Text('${(t['departures'] as List<dynamic>).length} sefer'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.tonal(onPressed: () => _editDepartures(routes[i], t), child: const Text('Seferler')),
                        IconButton(tooltip: 'Tarihleri düzenle', onPressed: () => _editTimetable(routes[i], t), icon: const Icon(Icons.edit_outlined)),
                        IconButton(
                          tooltip: 'Kopyala (ör. yaz tarifesi için)',
                          onPressed: () => _apply(() {
                            final copy = jsonDecode(jsonEncode(t)) as Map<String, dynamic>;
                            copy['name'] = '${t['name']} (kopya)';
                            (routes[i]['timetables'] as List<dynamic>).add(copy);
                          }),
                          icon: const Icon(Icons.copy_outlined),
                        ),
                        IconButton(
                          tooltip: 'Sil',
                          onPressed: () async {
                            if (await confirmDelete(context, 'Tarife')) {
                              _apply(() => (routes[i]['timetables'] as List<dynamic>).remove(t));
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _editTimetable(routes[i]),
                    icon: const Icon(Icons.add),
                    label: const Text('Tarife ekle'),
                  ),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(onPressed: () => _editRoute(), icon: const Icon(Icons.add), label: const Text('Hat ekle')),
        ),
      ],
    );
  }
}

// ─── Sefer saatleri ──────────────────────────────────────────────────────
final _timePattern = RegExp(r'^(\d{1,2})[:.](\d{2})$');

/// "9:05", "09.05" → "09:05"; geçersizse null.
String? normalizeTime(String v) {
  final m = _timePattern.firstMatch(v.trim());
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
}

String? _timeValidator(String v) => normalizeTime(v) == null ? 'Saat SS:DD biçiminde olmalı (ör. 09:30)' : null;

String daysText(List<dynamic>? days) =>
    days == null || days.isEmpty ? 'Her gün' : [for (final d in days) _dayNames[(d as int) - 1]].join(', ');

class _DeparturesPage extends StatefulWidget {
  const _DeparturesPage({required this.title, required this.departures});

  final String title;
  final List<Map<String, dynamic>> departures;

  @override
  State<_DeparturesPage> createState() => _DeparturesPageState();
}

class _DeparturesPageState extends State<_DeparturesPage> {
  late final List<Map<String, dynamic>> _list = widget.departures;

  void _sort() => _list.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));

  Future<Set<int>?> _pickDays(Set<int> initial) => showDialog<Set<int>>(
        context: context,
        builder: (_) => _DaysDialog(initial: initial),
      );

  Future<void> _edit([Map<String, dynamic>? d]) async {
    final v = await showFormDialog(
      context,
      title: d == null ? 'Sefer ekle' : 'Seferi düzenle',
      fields: [
        FieldSpec('time', 'Kalkış saati', initial: d?['time'] as String?, required: true, validator: _timeValidator),
        FieldSpec('arrival', 'Varış saati (isteğe bağlı)', initial: d?['arrival'] as String?, validator: _timeValidator),
        FieldSpec('note', 'Not (isteğe bağlı, ör. Balıklı üzerinden)', initial: d?['note'] as String?),
      ],
    );
    if (v == null || !mounted) return;
    final days = await _pickDays({...?(d?['days'] as List<dynamic>?)?.cast<int>()});
    if (days == null) return;
    final item = <String, dynamic>{
      'time': normalizeTime(v['time']!),
      if (v['arrival']!.isNotEmpty) 'arrival': normalizeTime(v['arrival']!),
      if (days.isNotEmpty && days.length < 7) 'days': (days.toList()..sort()),
      if (v['note']!.isNotEmpty) 'note': v['note'],
    };
    setState(() {
      if (d == null) {
        _list.add(item);
      } else {
        _list[_list.indexOf(d)] = item;
      }
      _sort();
    });
  }

  Future<void> _bulkAdd() async {
    final v = await showFormDialog(
      context,
      title: 'Toplu sefer ekle',
      fields: const [
        FieldSpec(
          'lines',
          'Saatler',
          kind: FieldKind.multiline,
          required: true,
          hint: 'Her satıra bir sefer: "07:30" ya da varışla birlikte "07:30-09:00". Hepsi aynı günlere eklenir.',
        ),
      ],
    );
    if (v == null || !mounted) return;
    final items = <Map<String, dynamic>>[];
    for (final line in splitLines(v['lines']!)) {
      final parts = line.split(RegExp(r'\s*[-–]\s*'));
      final time = normalizeTime(parts.first);
      final arrival = parts.length > 1 ? normalizeTime(parts[1]) : null;
      if (time == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Anlaşılamayan satır: "$line"')));
        return;
      }
      items.add({'time': time, 'arrival': ?arrival});
    }
    final days = await _pickDays(<int>{});
    if (days == null) return;
    setState(() {
      for (final item in items) {
        if (days.isNotEmpty && days.length < 7) item['days'] = days.toList()..sort();
        _list.add(item);
      }
      _sort();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          FilledButton(onPressed: () => Navigator.of(context).pop(_list), child: const Text('Tamam')),
          const SizedBox(width: 16),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('"Tamam"a bastıktan sonra ana sayfadaki "Kaydet" ile kaydetmeyi unutmayın.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonalIcon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Sefer ekle')),
                  OutlinedButton.icon(onPressed: _bulkAdd, icon: const Icon(Icons.playlist_add), label: const Text('Toplu ekle')),
                ],
              ),
              const SizedBox(height: 12),
              if (_list.isEmpty) const Text('Sefer yok.'),
              Card(
                child: Column(
                  children: [
                    for (final d in _list)
                      ListTile(
                        dense: true,
                        title: Text('${d['time']}${d['arrival'] != null ? '  →  ${d['arrival']}' : ''}'),
                        subtitle: Text([daysText(d['days'] as List<dynamic>?), if (d['note'] != null) d['note']].join(' · ')),
                        trailing: RowActions(
                          onEdit: () => _edit(d),
                          onDelete: () => setState(() => _list.remove(d)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaysDialog extends StatefulWidget {
  const _DaysDialog({required this.initial});

  final Set<int> initial;

  @override
  State<_DaysDialog> createState() => _DaysDialogState();
}

class _DaysDialogState extends State<_DaysDialog> {
  late final Set<int> _days = {...widget.initial};

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Hangi günler?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hiçbiri seçilmezse her gün sayılır.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var d = 1; d <= 7; d++)
                  FilterChip(
                    label: Text(_dayNames[d - 1]),
                    selected: _days.contains(d),
                    onSelected: (on) => setState(() {
                      if (on) {
                        _days.add(d);
                      } else {
                        _days.remove(d);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                TextButton(onPressed: () => setState(() => _days..clear()..addAll([1, 2, 3, 4, 5])), child: const Text('Hafta içi')),
                TextButton(onPressed: () => setState(() => _days..clear()..addAll([6, 7])), child: const Text('Hafta sonu')),
                TextButton(onPressed: () => setState(_days.clear), child: const Text('Her gün')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, _days), child: const Text('Tamam')),
        ],
      );
}
