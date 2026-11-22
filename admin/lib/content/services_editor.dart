import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../theme.dart';
import 'content_editor.dart';
import 'form_kit.dart';

const _types = {
  'taksi': 'Taksi durağı',
  'atm': 'ATM',
  'otopark': 'Otopark',
  'wc': 'WC',
  'sarj': 'Elektrikli araç şarj',
  'akaryakit': 'Akaryakıt',
};

const _icons = {
  'taksi': Icons.local_taxi_outlined,
  'atm': Icons.atm_outlined,
  'otopark': Icons.local_parking_outlined,
  'wc': Icons.wc_outlined,
  'sarj': Icons.ev_station_outlined,
  'akaryakit': Icons.local_gas_station_outlined,
};

/// Harita katmanları: taksi, ATM, otopark, WC, şarj, akaryakıt noktaları.
/// Uygulamada Harita ve Yakınımdakiler'de ayrı süzgeçlerle görünür.
class ServicesEditor extends StatelessWidget {
  const ServicesEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'services',
        title: 'Harita Katmanları',
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
  List<dynamic> get _points => widget.data.putIfAbsent('points', () => <dynamic>[]) as List<dynamic>;

  void _apply(VoidCallback f) {
    setState(f);
    widget.changed();
  }

  Future<void> _edit({Map<String, dynamic>? s, String? type}) async {
    final v = await showFormDialog(
      context,
      title: s == null ? 'Nokta ekle' : 'Noktayı düzenle',
      fields: [
        FieldSpec('type', 'Tür', kind: FieldKind.choice, options: _types,
            initial: (s?['type'] as String?) ?? type ?? 'taksi'),
        FieldSpec('name', 'Ad', initial: s?['name'] as String?, required: true,
            hint: 'Ör. "Merkez Taksi", "Ziraat Bankası ATM", "Liman Otoparkı"'),
        FieldSpec('latitude', 'Enlem', initial: s?['latitude']?.toString(), required: true,
            validator: numberValidator(min: 40, max: 41),
            hint: 'Google Haritalar\'da yere sağ tıklayın → ilk satırdaki sayılar (enlem, boylam).'),
        FieldSpec('longitude', 'Boylam', initial: s?['longitude']?.toString(), required: true,
            validator: numberValidator(min: 27, max: 28.5)),
        FieldSpec('note', 'Not (isteğe bağlı)', initial: s?['note'] as String?,
            hint: 'Ör. "Ziraat, Halkbank", "Ücretli", "22 kW, 2 soket"'),
        FieldSpec('hours', 'Saatler (isteğe bağlı)', initial: s?['hours'] as String?, hint: 'Ör. "7/24", "08:00–24:00"'),
        FieldSpec('phone', 'Telefon (isteğe bağlı)', initial: s?['phone'] as String?, validator: phoneValidator,
            hint: 'Taksi durakları için'),
      ],
    );
    if (v == null) return;
    String? opt(String key) => v[key]!.isEmpty ? null : v[key];
    final item = <String, dynamic>{
      'id': s?['id'] ?? newId('nk'),
      'type': v['type'],
      'name': v['name'],
      'latitude': parseNumber(v['latitude']!),
      'longitude': parseNumber(v['longitude']!),
      'note': ?opt('note'),
      'hours': ?opt('hours'),
      'phone': ?(opt('phone') == null ? null : normalizePhone(v['phone']!)),
    };
    _apply(() {
      if (s == null) {
        _points.add(item);
      } else {
        _points[_points.indexOf(s)] = item;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = _points.cast<Map<String, dynamic>>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionTitle(
          'Harita Katmanları (${all.length})',
          subtitle: 'Uygulamada Harita ve Yakınımdakiler\'de ayrı süzgeç olarak görünür; "en yakın ATM" gibi.',
          trailing: FilledButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Nokta ekle'),
          ),
        ),
        for (final e in _types.entries) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(_icons[e.key], color: AdminColors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${e.value} (${all.where((s) => s['type'] == e.key).length})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: () => _edit(type: e.key),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ekle'),
              ),
            ],
          ),
          for (final s in all.where((s) => s['type'] == e.key))
            Card(
              child: ListTile(
                title: Text(s['name'] as String),
                subtitle: Text(
                  [
                    '${s['latitude']}, ${s['longitude']}',
                    if (s['note'] != null) s['note'] as String,
                    if (s['hours'] != null) s['hours'] as String,
                  ].join(' · '),
                ),
                trailing: RowActions(
                  onEdit: () => _edit(s: s),
                  onDelete: () async {
                    if (await confirmDelete(context, 'Nokta')) _apply(() => _points.remove(s));
                  },
                ),
              ),
            ),
        ],
      ],
    );
  }
}
