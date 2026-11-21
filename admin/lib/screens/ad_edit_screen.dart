import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../file_pick.dart';
import '../models.dart';

/// Reklam ekleme / düzenleme. Kaydedilince `true` ile geri döner.
class AdEditScreen extends StatefulWidget {
  const AdEditScreen({super.key, required this.api, required this.slots, this.ad});

  final Api api;
  final List<AdSlotInfo> slots;
  final AdItem? ad;

  @override
  State<AdEditScreen> createState() => _AdEditScreenState();
}

class _AdEditScreenState extends State<AdEditScreen> {
  static const _maxBytes = 1024 * 1024;

  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.ad?.title);
  late final _advertiser = TextEditingController(text: widget.ad?.advertiser);
  late final _link = TextEditingController(text: widget.ad?.linkUrl);
  late final _priority = TextEditingController(text: '${widget.ad?.priority ?? 0}');
  late final Set<String> _slots = {...?widget.ad?.slotIds};
  late DateTime _start = widget.ad == null ? DateTime.now() : TrDate.toTrDay(widget.ad!.startsAt);
  late DateTime? _end = widget.ad?.endsAt == null ? null : TrDate.toTrDay(widget.ad!.endsAt!);
  late bool _active = widget.ad?.isActive ?? true;
  PickedImage? _image;
  bool _busy = false;
  String? _error;
  late final Future<List<AdStat>>? _stats =
      widget.ad == null ? null : widget.api.stats(adId: widget.ad!.id);

  @override
  void dispose() {
    _title.dispose();
    _advertiser.dispose();
    _link.dispose();
    _priority.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await pickImage();
    if (picked == null) return;
    if (picked.bytes.length > _maxBytes) {
      setState(() => _error = 'Görsel 1 MB\'tan büyük (${(picked.bytes.length / 1024).round()} KB). Küçültüp tekrar deneyin.');
      return;
    }
    setState(() {
      _image = picked;
      _error = null;
    });
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final initial = isEnd ? (_end ?? _start) : _start;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (isEnd) {
        _end = picked;
      } else {
        _start = picked;
        if (_end != null && _end!.isBefore(_start)) _end = _start;
      }
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (widget.ad == null && _image == null) {
      setState(() => _error = 'Görsel seçin.');
      return;
    }
    if (_slots.isEmpty) {
      setState(() => _error = 'En az bir reklam alanı seçin.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      var imagePath = widget.ad?.imagePath;
      if (_image != null) {
        imagePath = await widget.api.uploadImage(_image!.bytes, contentType: _image!.type);
      }
      final advertiser = _advertiser.text.trim();
      final link = _link.text.trim();
      await widget.api.saveAd(
        id: widget.ad?.id,
        slotIds: _slots.toList(),
        fields: {
          'title': _title.text.trim(),
          'advertiser': advertiser.isEmpty ? null : advertiser,
          'link_url': link.isEmpty ? null : link,
          'image_path': imagePath,
          'starts_at': TrDate.startOfDay(_start),
          'ends_at': _end == null ? null : TrDate.endOfDay(_end!),
          'is_active': _active,
          'priority': int.tryParse(_priority.text.trim()) ?? 0,
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reklam silinsin mi?'),
        content: const Text('Reklam, görseli ve istatistikleri kalıcı olarak silinir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await widget.api.deleteAd(widget.ad!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  String _dateText(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = _image != null
        ? Image.memory(_image!.bytes, fit: BoxFit.cover)
        : widget.ad != null
            ? Image.network(widget.api.publicImageUrl(widget.ad!.imagePath), fit: BoxFit.cover)
            : Center(child: Text('Görsel yok', style: TextStyle(color: scheme.outline)));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ad == null ? 'Yeni reklam' : 'Reklamı düzenle'),
        actions: [
          if (widget.ad != null)
            TextButton(onPressed: _busy ? null : _delete, child: const Text('Sil')),
          const SizedBox(width: 8),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AspectRatio(
                  aspectRatio: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColoredBox(color: scheme.surfaceContainerHighest, child: preview),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Görsel seç (1200×600, en fazla 1 MB)'),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Başlık *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Başlık gerekli' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _advertiser,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Reklam veren (isteğe bağlı, başlığın altında görünür)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _link,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Bağlantı (https://…, isteğe bağlı)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    return t.startsWith('https://') ? null : 'Bağlantı https:// ile başlamalı';
                  },
                ),
                const SizedBox(height: 16),
                Text('Reklam alanları *', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in widget.slots)
                      FilterChip(
                        label: Text(s.title),
                        tooltip: s.description,
                        selected: _slots.contains(s.id),
                        onSelected: (on) => setState(() {
                          if (on) {
                            _slots.add(s.id);
                          } else {
                            _slots.remove(s.id);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => _pickDate(isEnd: false),
                      child: Text('Başlangıç: ${_dateText(_start)}'),
                    ),
                    OutlinedButton(
                      onPressed: () => _pickDate(isEnd: true),
                      child: Text('Bitiş: ${_end == null ? 'süresiz' : _dateText(_end!)}'),
                    ),
                    if (_end != null)
                      TextButton(onPressed: () => setState(() => _end = null), child: const Text('Süresiz yap')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: TextFormField(
                        controller: _priority,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Öncelik', border: OutlineInputBorder()),
                        validator: (v) => int.tryParse(v?.trim() ?? '') == null ? 'Sayı girin' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Aynı alanda birden çok reklam varsa önceliği yüksek olan gösterilir; '
                          'eşitse sırayla döner.'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Yayında'),
                  subtitle: const Text('Kapatırsanız tarihler ne olursa olsun gösterilmez.'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: scheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(_busy ? 'Kaydediliyor…' : 'Kaydet'),
                ),
                if (_stats != null) ...[
                  const SizedBox(height: 32),
                  Text('Son 30 gün', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  FutureBuilder<List<AdStat>>(
                    future: _stats,
                    builder: (context, snap) {
                      final rows = snap.data;
                      if (rows == null) {
                        return snap.hasError ? Text(snap.error.toString()) : const LinearProgressIndicator();
                      }
                      if (rows.isEmpty) return const Text('Henüz gösterim yok.');
                      final titles = {for (final s in widget.slots) s.id: s.title};
                      return DataTable(
                        columns: const [
                          DataColumn(label: Text('Gün')),
                          DataColumn(label: Text('Alan')),
                          DataColumn(label: Text('Gösterim'), numeric: true),
                          DataColumn(label: Text('Tıklama'), numeric: true),
                        ],
                        rows: [
                          for (final r in rows)
                            DataRow(cells: [
                              DataCell(Text(r.day)),
                              DataCell(Text(titles[r.slotId] ?? r.slotId)),
                              DataCell(Text('${r.impressions}')),
                              DataCell(Text('${r.clicks}')),
                            ]),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
