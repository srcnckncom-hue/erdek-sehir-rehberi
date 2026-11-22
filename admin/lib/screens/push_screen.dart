import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../theme.dart';

/// Bildirim konuları (FCM topic) → paneldeki adı. Uygulamadaki PushTopic ve
/// supabase/functions/send-push içindeki TOPICS ile AYNI olmalı.
const pushTopics = {
  'duyurular': 'Önemli duyurular',
  'kesintiler': 'Su ve elektrik kesintileri',
  'ulasim': 'Ulaşım (feribot/otobüs)',
  'etkinlikler': 'Etkinlikler',
};

/// Duyuru türüne uygun bildirim konusu.
String pushTopicForCategory(String? category) => switch (category) {
      'kesinti' => 'kesintiler',
      'etkinlik' || 'pazar' => 'etkinlikler',
      _ => 'duyurular',
    };

/// Önizleme + onay penceresi; onaylanırsa gönderir. Gönderildiyse true.
/// Duyurular sayfasından da (hazır başlık/metinle) çağrılır.
Future<bool> confirmAndSendPush(
  BuildContext context,
  Api api, {
  required String title,
  required String body,
  String topic = 'duyurular',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Bildirim gönderilsin mi?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Uygulamada "${pushTopics[topic] ?? topic}" konusunu açan HERKESİN telefonuna şimdi gidecek. '
              'Gönderildikten sonra geri alınamaz.',
            ),
            const SizedBox(height: 16),
            PushPreview(title: title, body: body),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.send),
          label: const Text('Gönder'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await api.sendPush(title: title, body: body, topic: topic);
    messenger.showSnackBar(const SnackBar(content: Text('Bildirim gönderildi.')));
    return true;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Bildirim gönderilemedi: $e')));
    return false;
  }
}

/// iPhone kilit ekranı bildirimine benzeyen önizleme.
class PushPreview extends StatelessWidget {
  const PushPreview({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF1F5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                color: Colors.white,
                padding: const EdgeInsets.all(3),
                child: Image.asset('assets/logo_emblem.png'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'ERDEK REHBERİ',
                          style: TextStyle(fontSize: 11, color: AdminColors.muted, letterSpacing: 0.5),
                        ),
                      ),
                      Text('şimdi', style: TextStyle(fontSize: 11, color: AdminColors.muted.withValues(alpha: 0.8))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title.isEmpty ? 'Başlık' : title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AdminColors.navy),
                  ),
                  Text(
                    body.isEmpty ? 'Bildirim metni' : body,
                    style: const TextStyle(fontSize: 13, color: AdminColors.navy),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Panel → Bildirim Gönder: başlık + metin, önizleme, son gönderilenler.
class PushScreen extends StatefulWidget {
  const PushScreen({super.key, required this.api});

  final Api api;

  @override
  State<PushScreen> createState() => _PushScreenState();
}

class _PushScreenState extends State<PushScreen> {
  static const _titleMax = 80;
  static const _bodyMax = 240;

  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;
  String _topic = 'duyurular';
  late Future<List<Map<String, dynamic>>> _log = widget.api.pushLog();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Başlık ve metin gerekli.')));
      return;
    }
    setState(() => _sending = true);
    final sent = await confirmAndSendPush(context, widget.api, title: title, body: body, topic: _topic);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (sent) {
        _title.clear();
        _body.clear();
        _log = widget.api.pushLog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim Gönder')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AdminSectionTitle(
                    'Yeni bildirim',
                    subtitle: 'Elektrik/su kesintisi, yol kapanması, feribot iptali gibi ÖNEMLİ ve acil durumlar için. '
                        'Sık bildirim, kullanıcıların bildirimleri kapatmasına yol açar (24 saatte en fazla 10).',
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Konu', style: TextStyle(fontWeight: FontWeight.w600, color: AdminColors.muted)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final e in pushTopics.entries)
                                ChoiceChip(
                                  label: Text(e.value),
                                  selected: _topic == e.key,
                                  onSelected: (_) => setState(() => _topic = e.key),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Bildirim yalnızca uygulamada bu konuyu açanlara gider.',
                            style: TextStyle(fontSize: 12, color: AdminColors.muted),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _title,
                            maxLength: _titleMax,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Başlık',
                              hintText: 'Ör. Su kesintisi',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _body,
                            maxLength: _bodyMax,
                            minLines: 3,
                            maxLines: 5,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Metin',
                              hintText: 'Ör. Yarın 09:00–15:00 arası Cumhuriyet Mahallesi\'nde su kesintisi olacak.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Önizleme', style: TextStyle(fontWeight: FontWeight.w600, color: AdminColors.muted)),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: PushPreview(title: _title.text.trim(), body: _body.text.trim()),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _sending ? null : _send,
                              icon: _sending
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send),
                              label: const Text('Gönder'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AdminSectionTitle(
                    'Son gönderilenler',
                    trailing: IconButton(
                      tooltip: 'Yenile',
                      onPressed: () => setState(() => _log = widget.api.pushLog()),
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _log,
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Liste okunamadı: ${snap.error}\n'
                              '(0006_push_log.sql çalıştırıldı mı?)',
                            ),
                          ),
                        );
                      }
                      if (!snap.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final rows = snap.data!;
                      if (rows.isEmpty) {
                        return const Card(
                          child: Padding(padding: EdgeInsets.all(20), child: Text('Henüz bildirim gönderilmedi.')),
                        );
                      }
                      return Card(
                        child: Column(
                          children: [
                            for (var i = 0; i < rows.length; i++) ...[
                              if (i > 0) const Divider(),
                              ListTile(
                                leading: Icon(
                                  rows[i]['ok'] == true ? Icons.check_circle : Icons.error_outline,
                                  color: rows[i]['ok'] == true ? Colors.green : Colors.red,
                                ),
                                title: Text(rows[i]['title'] as String),
                                subtitle: Text(
                                  '${rows[i]['body']}\n${pushTopics[rows[i]['topic']] ?? rows[i]['topic'] ?? ''} · '
                                  '${_when(rows[i]['sent_at'] as String?)}'
                                  '${rows[i]['sent_by_email'] == null ? '' : ' · ${rows[i]['sent_by_email']}'}',
                                ),
                                isThreeLine: true,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _when(String? iso) {
    final t = DateTime.tryParse(iso ?? '')?.toUtc().add(const Duration(hours: 3));
    if (t == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)}.${t.year} ${two(t.hour)}:${two(t.minute)}';
  }
}
