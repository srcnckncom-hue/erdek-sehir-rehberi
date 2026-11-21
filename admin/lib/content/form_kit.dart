import 'package:material_ui/material_ui.dart';

/// Basit form diyaloğu: alanlar metin, çok satırlı metin, seçim ya da tarih.
enum FieldKind { text, multiline, choice, date }

class FieldSpec {
  const FieldSpec(
    this.key,
    this.label, {
    this.initial,
    this.kind = FieldKind.text,
    this.options = const {},
    this.required = false,
    this.validator,
    this.hint,
    this.keyboard,
  });

  final String key;
  final String label;
  final String? initial;
  final FieldKind kind;

  /// choice: değer → görünen ad
  final Map<String, String> options;
  final bool required;
  final String? Function(String value)? validator;
  final String? hint;
  final TextInputType? keyboard;
}

/// Kaydet'e basılırsa alan değerlerini (kırpılmış) döndürür, vazgeçilirse null.
/// Tarih alanlarının değeri `YYYY-MM-DD` ya da boş.
Future<Map<String, String>?> showFormDialog(
  BuildContext context, {
  required String title,
  required List<FieldSpec> fields,
}) =>
    showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _FormDialog(title: title, fields: fields),
    );

class _FormDialog extends StatefulWidget {
  const _FormDialog({required this.title, required this.fields});

  final String title;
  final List<FieldSpec> fields;

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _text = {
    for (final f in widget.fields)
      if (f.kind == FieldKind.text || f.kind == FieldKind.multiline)
        f.key: TextEditingController(text: f.initial ?? ''),
  };
  late final Map<String, String> _values = {
    for (final f in widget.fields)
      if (f.kind == FieldKind.choice || f.kind == FieldKind.date)
        f.key: f.initial ?? (f.kind == FieldKind.choice ? f.options.keys.first : ''),
  };
  String? _error;

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(FieldSpec f) async {
    final current = DateTime.tryParse(_values[f.key] ?? '');
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _values[f.key] = isoDate(picked));
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    for (final f in widget.fields) {
      if (f.kind == FieldKind.date && f.required && (_values[f.key] ?? '').isEmpty) {
        setState(() => _error = '${f.label} seçin.');
        return;
      }
    }
    Navigator.of(context).pop({
      for (final e in _text.entries) e.key: e.value.text.trim(),
      ..._values,
    });
  }

  Widget _field(FieldSpec f) {
    switch (f.kind) {
      case FieldKind.text:
      case FieldKind.multiline:
        return TextFormField(
          controller: _text[f.key],
          keyboardType: f.kind == FieldKind.multiline ? TextInputType.multiline : f.keyboard,
          minLines: f.kind == FieldKind.multiline ? 3 : 1,
          maxLines: f.kind == FieldKind.multiline ? 12 : 1,
          decoration: InputDecoration(
            labelText: f.required ? '${f.label} *' : f.label,
            helperText: f.hint,
            helperMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (f.required && t.isEmpty) return '${f.label} gerekli';
            if (t.isNotEmpty && f.validator != null) return f.validator!(t);
            return null;
          },
        );
      case FieldKind.choice:
        return DropdownButtonFormField<String>(
          initialValue: _values[f.key],
          decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder()),
          items: [
            for (final e in f.options.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) => setState(() => _values[f.key] = v ?? f.options.keys.first),
        );
      case FieldKind.date:
        final value = _values[f.key] ?? '';
        return Row(
          children: [
            Expanded(
              child: Text('${f.label}${f.required ? ' *' : ''}: ${value.isEmpty ? '—' : trDateText(value)}'),
            ),
            TextButton(onPressed: () => _pickDate(f), child: const Text('Seç')),
            if (value.isNotEmpty && !f.required)
              TextButton(onPressed: () => setState(() => _values[f.key] = ''), child: const Text('Temizle')),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final f in widget.fields) ...[
                  _field(f),
                  const SizedBox(height: 12),
                ],
                if (_error != null)
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Vazgeç')),
        FilledButton(onPressed: _submit, child: const Text('Tamam')),
      ],
    );
  }
}

Future<bool> confirmDelete(BuildContext context, String what) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$what silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    ) ??
    false;

// ─── Biçim yardımcıları ──────────────────────────────────────────────────
String _two(int n) => n.toString().padLeft(2, '0');

String isoDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// "2026-11-21" → "21.11.2026"
String trDateText(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : '${_two(d.day)}.${_two(d.month)}.${d.year}';
}

/// Türkiye saatiyle zaman damgası: "2026-11-21T09:00:00+03:00"
String trTimestamp(DateTime local) =>
    '${isoDate(local)}T${_two(local.hour)}:${_two(local.minute)}:00+03:00';

/// Şu an (Türkiye saati) zaman damgası.
String trNow() => trTimestamp(DateTime.now().toUtc().add(const Duration(hours: 3)));

/// ISO zaman damgasındaki tarih kısmı ("2026-11-21T..." → "2026-11-21").
String datePart(String? ts) => ts == null || ts.length < 10 ? '' : ts.substring(0, 10);

String newId(String prefix) => '$prefix-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

final _phonePattern = RegExp(r'^(\+90\d{10}|1\d{2,3})$');

/// "0266 123 45 67", "266 1234567", "+90 266..." → "+902661234567"; 112 → 112
String normalizePhone(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length <= 4) return digits;
  if (digits.length == 12 && digits.startsWith('90')) return '+$digits';
  if (digits.length == 11 && digits.startsWith('0')) return '+9$digits';
  if (digits.length == 10) return '+90$digits';
  return input.trim();
}

String? phoneValidator(String v) =>
    _phonePattern.hasMatch(normalizePhone(v)) ? null : 'Geçerli bir numara girin (ör. 0266 123 45 67 veya 112)';

/// "+902661234567" → "0266 123 45 67"
String formatPhone(String phone) {
  final d = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.length == 12 && d.startsWith('90')) {
    final n = d.substring(2);
    return '0${n.substring(0, 3)} ${n.substring(3, 6)} ${n.substring(6, 8)} ${n.substring(8)}';
  }
  return phone;
}

String? httpsValidator(String v) => v.startsWith('https://') ? null : 'https:// ile başlamalı';

String? Function(String) numberValidator({double? min, double? max}) => (v) {
      final n = double.tryParse(v.replaceAll(',', '.'));
      if (n == null) return 'Sayı girin (ör. 40.3991)';
      if ((min != null && n < min) || (max != null && n > max)) return '$min – $max arasında olmalı';
      return null;
    };

double? parseNumber(String v) => v.isEmpty ? null : double.tryParse(v.replaceAll(',', '.'));

/// Boş satırla ayrılmış paragraflar.
List<String> splitParagraphs(String v) =>
    v.split(RegExp(r'\n\s*\n')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

List<String> splitLines(String v) => v.split('\n').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
