import 'package:material_ui/material_ui.dart';

import 'api.dart';
import 'content/announcements_editor.dart';
import 'content/contacts_editor.dart';
import 'content/history_editor.dart';
import 'content/pharmacy_editor.dart';
import 'content/places_editor.dart';
import 'screens/ads_screen.dart';
import 'screens/login_screen.dart';

/// Panelin ana iskeleti: solda bölümler, sağda seçili sayfa.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.api});

  final Api api;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _items = [
    (Icons.campaign_outlined, 'Reklamlar'),
    (Icons.phone_outlined, 'Telefonlar'),
    (Icons.notifications_outlined, 'Duyurular'),
    (Icons.local_pharmacy_outlined, 'Nöbetçi Eczane'),
    (Icons.map_outlined, 'Gezilecek Yerler'),
    (Icons.history_edu_outlined, 'Erdek Tarihi'),
    (Icons.directions_boat_outlined, 'Ulaşım'),
  ];

  Widget _page() => switch (_index) {
        0 => AdsScreen(api: widget.api),
        1 => ContactsEditor(api: widget.api),
        2 => AnnouncementsEditor(api: widget.api),
        3 => PharmacyEditor(api: widget.api),
        4 => PlacesEditor(api: widget.api),
        5 => HistoryEditor(api: widget.api),
        _ => const _TransportSoon(),
      };

  Future<void> _signOut() async {
    widget.api.signOut();
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => LoginScreen(api: widget.api)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (i) => setState(() => _index = i),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Erdek\nRehberi', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextButton(onPressed: _signOut, child: const Text('Çıkış')),
                ),
              ),
            ),
            destinations: [
              for (final (icon, label) in _items)
                NavigationRailDestination(icon: Icon(icon), label: Text(label)),
            ],
          ),
          const VerticalDivider(width: 1),
          // Bölüm değişince sayfa sıfırdan kurulur (kaydedilmemiş değişiklik kaybolur).
          Expanded(child: KeyedSubtree(key: ValueKey(_index), child: _page())),
        ],
      ),
    );
  }
}

class _TransportSoon extends StatelessWidget {
  const _TransportSoon();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ulaşım')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Ulaşım (feribot / otobüs / şehir içi sefer saatleri) düzenleyicisi bir sonraki adımda eklenecek.\n'
              'O zamana kadar saatleri Claude\'a gönderin.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}
