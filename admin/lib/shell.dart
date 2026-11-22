import 'package:material_ui/material_ui.dart';

import 'api.dart';
import 'content/announcements_editor.dart';
import 'content/businesses_editor.dart';
import 'content/contacts_editor.dart';
import 'content/history_editor.dart';
import 'content/pharmacy_editor.dart';
import 'content/places_editor.dart';
import 'content/social_editor.dart';
import 'content/stories_editor.dart';
import 'content/transport_editor.dart';
import 'screens/ads_screen.dart';
import 'screens/login_screen.dart';
import 'screens/push_screen.dart';
import 'theme.dart';

/// Kenar çubuğundaki bir bölüm.
class _Section {
  const _Section(this.icon, this.label, this.build);

  final IconData icon;
  final String label;
  final Widget Function(Api api) build;
}

/// Kenar çubuğundaki grup ("Genel", "Rehber", "Keşfet").
class _Group {
  const _Group(this.title, this.sections);

  final String title;
  final List<_Section> sections;
}

final _groups = <_Group>[
  _Group('Genel', [
    _Section(Icons.campaign_outlined, 'Reklamlar', (api) => AdsScreen(api: api)),
    _Section(Icons.notifications_outlined, 'Duyurular', (api) => AnnouncementsEditor(api: api)),
    _Section(Icons.amp_stories_outlined, 'Hikâyeler', (api) => StoriesEditor(api: api)),
    _Section(Icons.send_outlined, 'Bildirim Gönder', (api) => PushScreen(api: api)),
    _Section(Icons.share_outlined, 'Sosyal Medya', (api) => SocialEditor(api: api)),
  ]),
  _Group('Şehir Rehberi', [
    _Section(Icons.local_pharmacy_outlined, 'Nöbetçi Eczane', (api) => PharmacyEditor(api: api)),
    _Section(Icons.phone_outlined, 'Telefonlar', (api) => ContactsEditor(api: api)),
    _Section(Icons.directions_boat_outlined, 'Ulaşım', (api) => TransportEditor(api: api)),
  ]),
  _Group('Keşfet', [
    _Section(Icons.storefront_outlined, 'İşletmeler', (api) => BusinessesEditor(api: api)),
    _Section(Icons.map_outlined, 'Gezilecek Yerler', (api) => PlacesEditor(api: api)),
    _Section(Icons.history_edu_outlined, 'Erdek Tarihi', (api) => HistoryEditor(api: api)),
  ]),
];

final _sections = [for (final g in _groups) ...g.sections];

/// Panelin ana iskeleti: solda gruplanmış bölümler, sağda seçili sayfa.
/// Dar ekranda (telefon/tablet) kenar çubuğu menüye dönüşür.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.api});

  final Api api;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  Future<void> _signOut() async {
    widget.api.signOut();
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => LoginScreen(api: widget.api)),
    );
  }

  Widget _sidebar({required bool closeOnSelect}) => _Sidebar(
        selected: _index,
        email: widget.api.email,
        onSelect: (i) {
          setState(() => _index = i);
          if (closeOnSelect) Navigator.of(context).pop();
        },
        onSignOut: _signOut,
      );

  @override
  Widget build(BuildContext context) {
    // Bölüm değişince sayfa sıfırdan kurulur (kaydedilmemiş değişiklik kaybolur).
    final page = KeyedSubtree(key: ValueKey(_index), child: _sections[_index].build(widget.api));
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _sidebar(closeOnSelect: false),
            Expanded(child: page),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AdminColors.sidebar,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        title: Text(_sections[_index].label),
      ),
      drawer: Drawer(
        backgroundColor: AdminColors.sidebar,
        child: _sidebar(closeOnSelect: true),
      ),
      body: page,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.onSelect,
    required this.onSignOut,
    this.email,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;
  final String? email;

  @override
  Widget build(BuildContext context) {
    var index = 0;
    final children = <Widget>[];
    for (final group in _groups) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
          child: Text(
            group.title.toUpperCase(),
            style: const TextStyle(
              color: AdminColors.sidebarMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
      for (final section in group.sections) {
        final i = index++;
        children.add(
          _SidebarItem(
            icon: section.icon,
            label: section.label,
            selected: i == selected,
            onTap: () => onSelect(i),
          ),
        );
      }
    }

    return Container(
      width: 260,
      color: AdminColors.sidebar,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Image.asset('assets/logo_emblem.png'),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Erdek Rehberi',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text('Yönetim Paneli', style: TextStyle(color: AdminColors.sidebarMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: ListView(padding: EdgeInsets.zero, children: children)),
            const Divider(color: Color(0x33FFFFFF)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
              child: Row(
                children: [
                  const Icon(Icons.account_circle_outlined, color: AdminColors.sidebarMuted, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email ?? 'Admin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AdminColors.sidebarMuted, fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onSignOut,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Çıkış'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: selected ? AdminColors.blue : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            hoverColor: const Color(0x14FFFFFF),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: selected ? Colors.white : AdminColors.sidebarMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFFD5DCE6),
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
