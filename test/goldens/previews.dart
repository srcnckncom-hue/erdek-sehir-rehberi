import 'package:erdek_rehberi/core/theme/app_icons.dart';
import 'package:erdek_rehberi/core/theme/app_theme.dart';
import 'package:erdek_rehberi/core/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

/// Tasarım kontrolü için SABİT verili önizlemeler. Gerçek veri bağlantısı
/// 4. adımda (lib/features/home). Buradaki metinler örnektir.
const heroImage = AssetImage('assets/images/hero_erdek.jpg');

const tabItems = [
  TabItem(label: 'Ana Sayfa', icon: AppIcons.tabHome),
  TabItem(label: 'Eczane', icon: AppIcons.tabPharmacy),
  TabItem(label: 'Vakitler', icon: AppIcons.tabPrayer),
  TabItem(label: 'Ulaşım', icon: AppIcons.tabTransport),
  TabItem(label: 'Rehber', icon: AppIcons.tabDirectory),
];

/// Görseldeki ana sayfanın bizim özelliklerimizle karşılığı.
class HomePreview extends StatelessWidget {
  const HomePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: FloatingTabBar(
        items: tabItems,
        currentIndex: 0,
        onSelected: (_) {},
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.searchHeight / 2),
                  child: HeroHeader(
                    image: heroImage,
                    greeting: 'İyi akşamlar, Erdek',
                    dayLabel: 'Cumartesi, Erdek',
                    locationLabel: 'Erdek, Balıkesir',
                    statusLabel: 'Güncel',
                    menuLabel: 'Menü',
                    bell: NotificationBell(count: 3, tooltip: 'Duyurular', onTap: () {}),
                    weather: const HeroWeather(
                      temperature: 16,
                      symbolCode: 'partlycloudy_day',
                      description: 'Parçalı bulutlu',
                      humidityLabel: '%72 Nem',
                      windLabel: '12 km/s',
                      rangeLabel: '14°/22°',
                    ),
                  ),
                ),
                const Positioned(
                  left: AppSpacing.page,
                  right: AppSpacing.page,
                  bottom: 0,
                  child: AppSearchBar(hint: 'Eczane, telefon, sefer veya duyuru ara...'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            SectionHeader(title: 'Hızlı İşlemlerim', actionLabel: 'Tümünü Gör', onAction: () {}),
            const SizedBox(height: AppSpacing.md),
            QuickActionGrid(
              columns: 3,
              children: [
                QuickActionChip(icon: AppIcons.pharmacy, label: 'Nöbetçi Eczane', tone: p.peach),
                QuickActionChip(icon: AppIcons.prayer, label: 'Namaz Vakitleri', tone: p.mint),
                QuickActionChip(icon: AppIcons.ferry, label: 'Feribot Saatleri', tone: p.aqua),
              ],
            ),
            const SizedBox(height: AppSpacing.gap),
            QuickActionGrid(
              columns: 4,
              children: [
                QuickActionTile(icon: AppIcons.announcements, label: 'Duyurular', iconColor: p.iconPurple),
                QuickActionTile(icon: AppIcons.contacts, label: 'Önemli Telefonlar', iconColor: p.iconBlue),
                QuickActionTile(icon: AppIcons.bus, label: 'Otobüs Saatleri', iconColor: p.iconPurple),
                QuickActionTile(icon: AppIcons.imsakiye, label: 'İmsakiye', iconColor: p.iconRed),
                QuickActionTile(icon: AppIcons.outage, label: 'Kesintiler', iconColor: p.iconCrimson),
                QuickActionTile(icon: AppIcons.market, label: 'Pazar Günleri', iconColor: p.iconPurple),
                QuickActionTile(icon: AppIcons.event, label: 'Etkinlikler', iconColor: p.iconOrange),
                QuickActionTile(icon: AppIcons.emergency, label: 'Acil 112', iconColor: p.iconCoral),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            const Padding(
              padding: AppSpacing.pagePadding,
              child: AdCard(
                image: heroImage,
                title: 'ÖRNEK İşletme — Deniz Restoran',
                subtitle: 'Reklam kartı önizlemesi (home_feed_1)',
                adLabel: 'Reklam',
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            SectionHeader(title: 'Şehir Hizmetleri', accentColor: p.accentRed),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: AppSpacing.pagePadding,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: FeatureCard(
                        icon: AppIcons.pill,
                        overline: 'Bugünün nöbetçi eczanesi',
                        title: 'ÖRNEK Eczane 1',
                        subtitle: '08:30\'a kadar · Erdek merkez',
                        tagLabel: 'Nöbetçi',
                        tagIcon: AppIcons.clock,
                        actions: [
                          CardAction(icon: AppIcons.call, label: 'Ara', onTap: () {}),
                          CardAction(icon: AppIcons.directions, label: 'Yol tarifi', onTap: () {}),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gap),
                    Expanded(
                      child: InfoCard(
                        title: 'Sıradaki Vakit',
                        icon: AppIcons.prayer,
                        label: 'Yatsı',
                        value: '19:00',
                        footnote: '1 sa 12 dk kaldı',
                      ),
                    ),
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
