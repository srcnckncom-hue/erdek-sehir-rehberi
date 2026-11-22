import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../theme.dart';
import 'content_editor.dart';
import 'form_kit.dart';

const _weekdays = {
  '1': 'Pazartesi',
  '2': 'Salı',
  '3': 'Çarşamba',
  '4': 'Perşembe',
  '5': 'Cuma',
  '6': 'Cumartesi',
  '7': 'Pazar',
};

const _months = {
  '1': 'Ocak', '2': 'Şubat', '3': 'Mart', '4': 'Nisan', '5': 'Mayıs', '6': 'Haziran',
  '7': 'Temmuz', '8': 'Ağustos', '9': 'Eylül', '10': 'Ekim', '11': 'Kasım', '12': 'Aralık',
};

final _timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

String? _timeValidator(String v) => _timePattern.hasMatch(v) ? null : 'SS:DD biçiminde yazın, ör. 08:00';

/// Semt pazarları: uygulamada gün gün listelenir; kurulduğu gün ana sayfada
/// "Bugün pazar var" görünür.
class MarketsEditor extends StatelessWidget {
  const MarketsEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'markets',
        title: 'Semt Pazarları',
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
  List<dynamic> get _markets => widget.data.putIfAbsent('markets', () => <dynamic>[]) as List<dynamic>;

  void _apply(VoidCallback f) {
    setState(f);
    widget.changed();
  }

  Future<void> _edit([Map<String, dynamic>? m]) async {
    final v = await showFormDialog(
      context,
      title: m == null ? 'Pazar ekle' : 'Pazarı düzenle',
      fields: [
        FieldSpec('name', 'Pazar adı', initial: m?['name'] as String?, required: true, hint: 'Ör. "Merkez Salı Pazarı"'),
        FieldSpec('weekday', 'Gün', kind: FieldKind.choice, options: _weekdays, initial: m?['weekday']?.toString() ?? '2'),
        FieldSpec('startTime', 'Başlangıç saati (isteğe bağlı)', initial: m?['startTime'] as String?,
            validator: _timeValidator, hint: 'Ör. 08:00'),
        FieldSpec('endTime', 'Bitiş saati (isteğe bağlı; boşsa 14:00 sayılır)', initial: m?['endTime'] as String?,
            validator: _timeValidator, hint: 'Ör. 14:00'),
        FieldSpec('place', 'Yer', initial: m?['place'] as String?, hint: 'Ör. "Belediye pazar yeri, Cumhuriyet Mah."'),
        FieldSpec('latitude', 'Enlem (isteğe bağlı)', initial: m?['latitude']?.toString(),
            validator: numberValidator(min: 40, max: 41), hint: 'Yol tarifi için'),
        FieldSpec('longitude', 'Boylam (isteğe bağlı)', initial: m?['longitude']?.toString(),
            validator: numberValidator(min: 27, max: 28.5)),
        FieldSpec('months', 'Yalnızca bu aylarda (boşsa bütün yıl)', kind: FieldKind.multiChoice, options: _months,
            initial: (m?['months'] as List<dynamic>?)?.join(','), hint: 'Yaz pazarları için ör. Haziran, Temmuz, Ağustos'),
        FieldSpec('note', 'Not (isteğe bağlı)', initial: m?['note'] as String?, hint: 'Ör. "Bayramda kurulmaz"'),
      ],
    );
    if (v == null) return;
    final lat = parseNumber(v['latitude']!);
    final lng = parseNumber(v['longitude']!);
    final messenger = ScaffoldMessenger.of(context);
    if ((lat == null) != (lng == null)) {
      messenger.showSnackBar(const SnackBar(content: Text('Enlem ve boylam birlikte girilmeli.')));
      return;
    }
    String? opt(String key) => v[key]!.isEmpty ? null : v[key];
    final start = opt('startTime');
    final end = opt('endTime');
    if (start != null && end != null && end.compareTo(start) <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Bitiş saati başlangıçtan sonra olmalı.')));
      return;
    }
    final months = [for (final x in v['months']!.split(',')) if (x.isNotEmpty) int.parse(x)];
    final item = <String, dynamic>{
      'id': m?['id'] ?? newId('pzr'),
      'name': v['name'],
      'weekday': int.parse(v['weekday']!),
      'startTime': ?start,
      'endTime': ?end,
      'place': ?opt('place'),
      'latitude': ?lat,
      'longitude': ?lng,
      if (months.isNotEmpty) 'months': months,
      'note': ?opt('note'),
    };
    _apply(() {
      if (m == null) {
        _markets.add(item);
      } else {
        _markets[_markets.indexOf(m)] = item;
      }
      _markets.sort((a, b) =>
          ((a as Map<String, dynamic>)['weekday'] as int).compareTo((b as Map<String, dynamic>)['weekday'] as int));
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = _markets.cast<Map<String, dynamic>>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionTitle(
          'Semt Pazarları (${all.length})',
          subtitle: 'Güne göre sıralanır. Kurulduğu gün uygulamanın ana sayfasında "Bugün pazar var" görünür.',
          trailing: FilledButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: const Text('Pazar ekle'),
          ),
        ),
        if (all.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Henüz pazar eklenmedi.'))),
        for (final m in all)
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AdminColors.background,
                child: Icon(Icons.storefront_outlined, color: AdminColors.blue),
              ),
              title: Text(m['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                [
                  _weekdays['${m['weekday']}'] ?? '',
                  if (m['startTime'] != null) '${m['startTime']}${m['endTime'] == null ? '' : '–${m['endTime']}'}',
                  if (m['place'] != null) m['place'] as String,
                  if (m['months'] != null)
                    'Yalnızca ${[for (final x in m['months'] as List<dynamic>) _months['$x']].join(', ')}',
                ].join(' · '),
              ),
              trailing: RowActions(
                onEdit: () => _edit(m),
                onDelete: () async {
                  if (await confirmDelete(context, 'Pazar')) _apply(() => _markets.remove(m));
                },
              ),
            ),
          ),
      ],
    );
  }
}
