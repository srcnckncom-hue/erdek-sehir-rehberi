import 'package:erdek_rehberi/core/theme/app_icons.dart';
import 'package:erdek_rehberi/core/theme/app_theme.dart';
import 'package:erdek_rehberi/core/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

/// Tasarım kontrolü için bileşen kataloğu (görselde olmayan durumlar).
/// Ana sayfa artık gerçek ekranla (AppShell) çekiliyor.
const heroImage = AssetImage('assets/images/hero_erdek.jpg');

/// Görselde olmayan durumlar + bileşen kataloğu.
class ComponentGallery extends StatelessWidget {
  const ComponentGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Bileşen kataloğu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(title: 'Bilgi şeritleri'),
            const SizedBox(height: AppSpacing.md),
            InfoBanner(
              icon: AppIcons.info,
              message: 'ÖRNEK VERİ — Bu bilgiler gerçek değildir.',
            ),
            const SizedBox(height: AppSpacing.sm),
            InfoBanner(
              icon: AppIcons.offline,
              message: 'Çevrimdışı · Son güncelleme: bugün 10:42',
            ),
            const SizedBox(height: AppSpacing.section),
            const SectionHeader(title: 'Boş durum'),
            MessageView(
              icon: StateIcons.empty,
              title: 'Bugün için kayıt yok',
              message: 'Nöbet listesi henüz yayınlanmadı. Lütfen 112\'yi arayın veya daha sonra tekrar deneyin.',
            ),
            const SectionHeader(title: 'Hata durumu'),
            MessageView(
              icon: StateIcons.error,
              iconColor: p.accentRed,
              title: 'Bilgiler yüklenemedi',
              message: 'İnternet bağlantınızı kontrol edin.',
              actionLabel: 'Tekrar dene',
              onAction: () {},
            ),
            const SectionHeader(title: 'Yükleniyor'),
            const SizedBox(height: AppSpacing.md),
            const SkeletonList(count: 3),
            const SizedBox(height: AppSpacing.section),
            const SectionHeader(title: 'Reklam kartı (2:1)'),
            const SizedBox(height: AppSpacing.md),
            const Padding(
              padding: AppSpacing.pagePadding,
              child: AdCard(
                image: heroImage,
                title: 'ÖRNEK Tekne Turu',
                subtitle: 'Görsel ölçüsü: 1200×600 px',
                adLabel: 'Reklam',
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            const SectionHeader(title: 'Bildirim zili (koyu zemin)'),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A3A66),
                  borderRadius: AppRadius.tileAll,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NotificationBell(count: 3, tooltip: 'Duyurular', onTap: () {}),
                    NotificationBell(count: 12, tooltip: 'Duyurular', onTap: () {}),
                    NotificationBell(count: 0, tooltip: 'Duyurular', onTap: () {}),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
