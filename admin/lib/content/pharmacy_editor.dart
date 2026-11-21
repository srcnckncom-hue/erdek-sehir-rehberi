import 'package:material_ui/material_ui.dart';

import '../api.dart';
import 'content_editor.dart';
import 'form_kit.dart';

/// Nöbetçi eczane: eczane listesi + gün gün nöbet takvimi.
/// (Nöbet günü sabah 08:30'da değişir; tarih, nöbetin BAŞLADIĞI gündür.)
class PharmacyEditor extends StatelessWidget {
  const PharmacyEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'pharmacy',
        title: 'Nöbetçi Eczane',
        validate: (data) =>
            (data['pharmacies'] as List<dynamic>).isEmpty ? 'En az bir eczane olmalı.' : null,
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
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  List<dynamic> get _pharmacies => widget.data['pharmacies'] as List<dynamic>;
  List<dynamic> get _duties => widget.data['duties'] as List<dynamic>;

  void _apply(VoidCallback f) {
    setState(f);
    widget.changed();
  }

  Future<void> _editPharmacy([Map<String, dynamic>? p]) async {
    final v = await showFormDialog(
      context,
      title: p == null ? 'Eczane ekle' : 'Eczaneyi düzenle',
      fields: [
        FieldSpec('name', 'Eczane adı', initial: p?['name'] as String?, required: true),
        FieldSpec('address', 'Adres', initial: p?['address'] as String?, required: true),
        FieldSpec(
          'phone',
          'Telefon',
          initial: p == null ? null : formatPhone(p['phone'] as String),
          required: true,
          validator: phoneValidator,
          keyboard: TextInputType.phone,
        ),
        FieldSpec(
          'lat',
          'Enlem (isteğe bağlı)',
          initial: p?['lat']?.toString(),
          validator: numberValidator(min: 40, max: 41),
          hint: 'Haritada yol tarifi için. Google Haritalar\'da yere sağ tıklayınca ilk sayı.',
        ),
        FieldSpec('lng', 'Boylam (isteğe bağlı)', initial: p?['lng']?.toString(), validator: numberValidator(min: 27, max: 28.5)),
      ],
    );
    if (v == null) return;
    final lat = parseNumber(v['lat']!);
    final lng = parseNumber(v['lng']!);
    if ((lat == null) != (lng == null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlem ve boylam birlikte girilmeli.')));
      }
      return;
    }
    final item = <String, dynamic>{
      'id': p?['id'] ?? newId('eczane'),
      'name': v['name'],
      'address': v['address'],
      'phone': normalizePhone(v['phone']!),
      'lat': ?lat,
      'lng': ?lng,
    };
    _apply(() {
      if (p == null) {
        _pharmacies.add(item);
      } else {
        _pharmacies[_pharmacies.indexOf(p)] = item;
      }
    });
  }

  void _deletePharmacy(Map<String, dynamic> p) {
    _apply(() {
      _pharmacies.remove(p);
      for (final d in _duties.cast<Map<String, dynamic>>()) {
        (d['pharmacyIds'] as List<dynamic>).remove(p['id']);
      }
      _duties.removeWhere((d) => ((d as Map<String, dynamic>)['pharmacyIds'] as List<dynamic>).isEmpty);
    });
  }

  Map<String, dynamic>? _dutyFor(String date) {
    for (final d in _duties.cast<Map<String, dynamic>>()) {
      if (d['date'] == date) return d;
    }
    return null;
  }

  Future<void> _editDay(String date) async {
    final current = {...?(_dutyFor(date)?['pharmacyIds'] as List<dynamic>?)?.cast<String>()};
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _DayDialog(
        date: date,
        pharmacies: _pharmacies.cast<Map<String, dynamic>>(),
        selected: current,
      ),
    );
    if (result == null) return;
    _apply(() {
      _duties.removeWhere((d) => (d as Map<String, dynamic>)['date'] == date);
      if (result.isNotEmpty) {
        _duties.add({'date': date, 'pharmacyIds': result.toList()});
        _duties.sort((a, b) => ((a as Map<String, dynamic>)['date'] as String)
            .compareTo((b as Map<String, dynamic>)['date'] as String));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final names = {for (final p in _pharmacies.cast<Map<String, dynamic>>()) p['id']: p['name'] as String};
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Eczaneler', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final p in _pharmacies.cast<Map<String, dynamic>>())
          Card(
            child: ListTile(
              title: Text(p['name'] as String),
              subtitle: Text('${p['address']} · ${formatPhone(p['phone'] as String)}'),
              trailing: RowActions(
                onEdit: () => _editPharmacy(p),
                onDelete: () async {
                  if (await confirmDelete(context, 'Eczane (nöbet günlerinden de çıkarılır)')) _deletePharmacy(p);
                },
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: () => _editPharmacy(), icon: const Icon(Icons.add), label: const Text('Eczane ekle')),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Text('Nöbet takvimi', style: Theme.of(context).textTheme.titleLarge)),
            IconButton(
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
              icon: const Icon(Icons.chevron_left),
            ),
            Text('${months[_month.month - 1]} ${_month.year}'),
            IconButton(
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const Text('Güne tıklayıp o gün nöbetçi olan eczaneleri seçin. Nöbet sabah 08:30\'da başlar.'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var day = 1; day <= daysInMonth; day++)
                Builder(builder: (context) {
                  final date = isoDate(DateTime(_month.year, _month.month, day));
                  final ids = (_dutyFor(date)?['pharmacyIds'] as List<dynamic>?)?.cast<String>() ?? const <String>[];
                  return ListTile(
                    dense: true,
                    leading: SizedBox(width: 90, child: Text(trDateText(date))),
                    title: Text(
                      ids.isEmpty ? '— nöbetçi girilmemiş —' : ids.map((id) => names[id] ?? id).join(', '),
                      style: ids.isEmpty ? TextStyle(color: Theme.of(context).colorScheme.error) : null,
                    ),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: () => _editDay(date),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayDialog extends StatefulWidget {
  const _DayDialog({required this.date, required this.pharmacies, required this.selected});

  final String date;
  final List<Map<String, dynamic>> pharmacies;
  final Set<String> selected;

  @override
  State<_DayDialog> createState() => _DayDialogState();
}

class _DayDialogState extends State<_DayDialog> {
  late final Set<String> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('${trDateText(widget.date)} nöbetçisi'),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final p in widget.pharmacies)
                CheckboxListTile(
                  title: Text(p['name'] as String),
                  value: _selected.contains(p['id']),
                  onChanged: (on) => setState(() {
                    if (on ?? false) {
                      _selected.add(p['id'] as String);
                    } else {
                      _selected.remove(p['id']);
                    }
                  }),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, _selected), child: const Text('Tamam')),
        ],
      );
}
