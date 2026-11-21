import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../models.dart';
import 'ad_edit_screen.dart';

/// Reklam listesi + son 30 günün gösterim/tıklama özeti.
class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key, required this.api});

  final Api api;

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _Data {
  const _Data(this.ads, this.slots, this.stats);

  final List<AdItem> ads;
  final List<AdSlotInfo> slots;
  final List<AdStat> stats;
}

class _AdsScreenState extends State<AdsScreen> {
  late Future<_Data> _future = _load();

  Future<_Data> _load() async {
    final results = await Future.wait([widget.api.ads(), widget.api.slots(), widget.api.stats()]);
    return _Data(
      results[0] as List<AdItem>,
      results[1] as List<AdSlotInfo>,
      results[2] as List<AdStat>,
    );
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _open(List<AdSlotInfo> slots, [AdItem? ad]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdEditScreen(api: widget.api, slots: slots, ad: ad)),
    );
    if (changed ?? false) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reklamlar'),
        actions: [
          IconButton(tooltip: 'Yenile', onPressed: _reload, icon: const Icon(Icons.refresh)),
          Center(child: Text(widget.api.email ?? '')),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<_Data>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snap.error.toString()),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _reload, child: const Text('Tekrar dene')),
                ],
              ),
            );
          }
          final data = snap.data;
          if (data == null) return const Center(child: CircularProgressIndicator());

          final slotTitles = {for (final s in data.slots) s.id: s.title};
          final now = DateTime.now().toUtc();
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  const Text(
                    'Önerilen görsel: 1200×600 px (2:1), JPG/PNG/WEBP, en fazla 1 MB. '
                    'Sayılar son 30 günü gösterir.',
                  ),
                  const SizedBox(height: 12),
                  if (data.ads.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Henüz reklam yok. "Yeni reklam" ile ekleyin.')),
                    ),
                  for (final ad in data.ads)
                    _AdTile(
                      ad: ad,
                      imageUrl: widget.api.publicImageUrl(ad.imagePath),
                      slotTitles: slotTitles,
                      stats: [for (final s in data.stats) if (s.adId == ad.id) s],
                      live: ad.isLive(now),
                      onTap: () => _open(data.slots, ad),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FutureBuilder<_Data>(
        future: _future,
        builder: (context, snap) => snap.data == null
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                onPressed: () => _open(snap.data!.slots),
                icon: const Icon(Icons.add),
                label: const Text('Yeni reklam'),
              ),
      ),
    );
  }
}

class _AdTile extends StatelessWidget {
  const _AdTile({
    required this.ad,
    required this.imageUrl,
    required this.slotTitles,
    required this.stats,
    required this.live,
    required this.onTap,
  });

  final AdItem ad;
  final String imageUrl;
  final Map<String, String> slotTitles;
  final List<AdStat> stats;
  final bool live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final impressions = stats.fold<int>(0, (a, s) => a + s.impressions);
    final clicks = stats.fold<int>(0, (a, s) => a + s.clicks);
    final ctr = impressions == 0 ? '—' : '%${(clicks * 100 / impressions).toStringAsFixed(1)}';
    final range = '${TrDate.format(ad.startsAt)} – ${ad.endsAt == null ? 'süresiz' : TrDate.format(ad.endsAt!)}';
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 160,
                  height: 80,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(color: scheme.surfaceContainerHighest),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(ad.title, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Chip(
                          label: Text(live ? 'Yayında' : (ad.isActive ? 'Beklemede / bitti' : 'Kapalı')),
                          backgroundColor: live ? const Color(0xFFC0F4D8) : scheme.surfaceContainerHighest,
                        ),
                      ],
                    ),
                    if (ad.advertiser != null) Text(ad.advertiser!),
                    Text(range),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final id in ad.slotIds)
                          Chip(label: Text(slotTitles[id] ?? id), visualDensity: VisualDensity.compact),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Gösterim: $impressions · Tıklama: $clicks · Tıklama oranı: $ctr'),
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
