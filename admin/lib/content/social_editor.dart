import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../theme.dart';
import 'content_editor.dart';

const _accounts = [
  ('instagram', 'Instagram', 'https://instagram.com/hesapadi', Icons.camera_alt_outlined),
  ('facebook', 'Facebook', 'https://facebook.com/sayfaadi', Icons.facebook),
  ('x', 'X (Twitter)', 'https://x.com/hesapadi', Icons.alternate_email),
];

/// Uygulamadaki sosyal medya düğmeleri (☰ menü ve Ayarlar).
/// Boş bırakılan hesap uygulamada görünmez.
class SocialEditor extends StatelessWidget {
  const SocialEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'social',
        title: 'Sosyal Medya',
        validate: (data) {
          for (final (key, label, _, _) in _accounts) {
            final v = (data[key] as String?) ?? '';
            if (v.isNotEmpty && !v.startsWith('https://')) return '$label adresi https:// ile başlamalı.';
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
  late final Map<String, TextEditingController> _controllers = {
    for (final (key, _, _, _) in _accounts) key: TextEditingController(text: (widget.data[key] as String?) ?? ''),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _update(String key, String value) {
    final v = value.trim();
    if (v.isEmpty) {
      widget.data.remove(key);
    } else {
      widget.data[key] = v;
    }
    widget.changed();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminSectionTitle(
              'Hesap adresleri',
              subtitle: 'Uygulamada ☰ menünün altında ve Ayarlar sayfasında düğme olarak görünür.',
            ),
            for (final (key, label, hint, icon) in _accounts) ...[
              TextField(
                controller: _controllers[key],
                onChanged: (v) => _update(key, v),
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  prefixIcon: Icon(icon),
                  labelText: label,
                  hintText: hint,
                  helperText: 'Boş bırakırsanız uygulamada gösterilmez.',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
