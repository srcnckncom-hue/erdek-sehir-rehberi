import 'package:material_ui/material_ui.dart';

/// Reklam alanı. Ekranda istediğin yere `AdSlot(id: 'home_feed_1')` koyman
/// yeterli. Slotta aktif reklam yoksa hiç yer kaplamaz.
///
/// ŞİMDİLİK BOŞ: Supabase bağlantısı, gösterim/tıklama sayımı ve
/// interstitial 9. adımda eklenecek. O zamana kadar her slot boş döner.
class AdSlot extends StatelessWidget {
  const AdSlot({super.key, required this.id, this.padding = EdgeInsets.zero});

  /// Sabit slot kimliği (ör. home_feed_1, pharmacy_bottom).
  final String id;

  /// Reklam varsa etrafına uygulanacak boşluk (yoksa uygulanmaz).
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
