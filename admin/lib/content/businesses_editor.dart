import 'package:material_ui/material_ui.dart';

import '../api.dart';
import '../file_pick.dart';
import '../theme.dart';
import 'content_editor.dart';
import 'form_kit.dart';
import 'photo_strip.dart';

/// Kategori ikonları (uygulamada karşılığı: BusinessIcon).
const _icons = {
  'food': 'Yemek (çatal-bıçak)',
  'cafe': 'Kafe (fincan)',
  'hotel': 'Konaklama (yatak)',
  'market': 'Market (sepet)',
  'shopping': 'Alışveriş (çanta)',
  'service': 'Hizmet (anahtar)',
  'car': 'Oto / ulaşım (araba)',
  'health': 'Sağlık (kalp)',
  'beauty': 'Güzellik / kuaför (makas)',
  'other': 'Diğer (dükkân)',
};

const _iconData = {
  'food': Icons.restaurant_outlined,
  'cafe': Icons.local_cafe_outlined,
  'hotel': Icons.hotel_outlined,
  'market': Icons.shopping_cart_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'service': Icons.build_outlined,
  'car': Icons.directions_car_outlined,
  'health': Icons.favorite_outline,
  'beauty': Icons.content_cut,
  'other': Icons.storefront_outlined,
};

/// İşletmeler: önce kategoriler, sonra işletmeler (fotoğraflı).
/// Uygulamada kategoriler bu sırayla, işletmeler bu sırayla listelenir.
class BusinessesEditor extends StatelessWidget {
  const BusinessesEditor({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) => ContentEditor(
        api: api,
        docId: 'businesses',
        title: 'İşletmeler',
        validate: (data) {
          final ids = {for (final c in data['categories'] as List<dynamic>) (c as Map<String, dynamic>)['id']};
          for (final b in (data['businesses'] as List<dynamic>).cast<Map<String, dynamic>>()) {
            if (!ids.contains(b['categoryId'])) return '"${b['name']}" için kategori seçin.';
          }
          return null;
        },
        builder: (context, data, changed) => _Body(api: api, data: data, changed: changed),
      );
}

class _Body extends StatefulWidget {
  const _Body({required this.api, required this.data, required this.changed});

  final Api api;
  final Map<String, dynamic> data;
  final VoidCallback changed;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  static const _maxPhotoBytes = 2 * 1024 * 1024;
  static const _maxPhotos = 10;

  /// Liste süzgeci: null = tüm kategoriler.
  String? _filter;
  String? _uploadingFor;

  List<dynamic> get _categories => widget.data.putIfAbsent('categories', () => <dynamic>[]) as List<dynamic>;
  List<dynamic> get _businesses => widget.data.putIfAbsent('businesses', () => <dynamic>[]) as List<dynamic>;

  Map<String, String> get _categoryOptions => {
        for (final c in _categories.cast<Map<String, dynamic>>()) c['id'] as String: c['title'] as String,
      };

  void _apply(VoidCallback f) {
    setState(f);
    widget.changed();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  int _countIn(String categoryId) =>
      _businesses.cast<Map<String, dynamic>>().where((b) => b['categoryId'] == categoryId).length;

  // ─── Kategoriler ──────────────────────────────────────────────────────
  Future<void> _editCategory([Map<String, dynamic>? c]) async {
    final v = await showFormDialog(
      context,
      title: c == null ? 'Kategori ekle' : 'Kategoriyi düzenle',
      fields: [
        FieldSpec('title', 'Kategori adı', initial: c?['title'] as String?, required: true, hint: 'Ör. Yeme-İçme'),
        FieldSpec('icon', 'İkon', kind: FieldKind.choice, options: _icons, initial: (c?['icon'] as String?) ?? 'other'),
      ],
    );
    if (v == null) return;
    _apply(() {
      if (c == null) {
        _categories.add(<String, dynamic>{'id': newId('kat'), 'title': v['title'], 'icon': v['icon']});
      } else {
        c
          ..['title'] = v['title']
          ..['icon'] = v['icon'];
      }
    });
  }

  Future<void> _deleteCategory(int i) async {
    final c = _categories[i] as Map<String, dynamic>;
    final count = _countIn(c['id'] as String);
    if (count > 0) {
      _toast('Bu kategoride $count işletme var. Önce onları başka kategoriye taşıyın ya da silin.');
      return;
    }
    if (await confirmDelete(context, 'Kategori')) {
      _apply(() {
        _categories.removeAt(i);
        if (_filter == c['id']) _filter = null;
      });
    }
  }

  // ─── İşletmeler ───────────────────────────────────────────────────────
  Future<void> _editBusiness([Map<String, dynamic>? b]) async {
    if (_categories.isEmpty) {
      _toast('Önce en az bir kategori ekleyin.');
      return;
    }
    final options = _categoryOptions;
    final initialCategory = (b?['categoryId'] as String?) ?? _filter;
    final v = await showFormDialog(
      context,
      title: b == null ? 'İşletme ekle' : 'İşletmeyi düzenle',
      fields: [
        FieldSpec('name', 'İşletme adı', initial: b?['name'] as String?, required: true),
        FieldSpec(
          'categoryId',
          'Kategori',
          kind: FieldKind.choice,
          options: options,
          initial: options.containsKey(initialCategory) ? initialCategory : null,
        ),
        FieldSpec('summary', 'Kısa tanım (listede görünür)', initial: b?['summary'] as String?,
            hint: 'Ör. "Ev yemekleri ve ızgara"'),
        FieldSpec('description', 'Ayrıntılı tanıtım (isteğe bağlı)', kind: FieldKind.multiline,
            initial: b?['description'] as String?, hint: 'Paragrafları BOŞ SATIRLA ayırın.'),
        FieldSpec('hours', 'Çalışma saatleri (isteğe bağlı)', initial: b?['hours'] as String?,
            hint: 'Ör. "Her gün 09:00–23:00"'),
        FieldSpec('phone', 'Telefon (isteğe bağlı)', initial: _phoneText(b?['phone']),
            validator: phoneValidator, keyboard: TextInputType.phone),
        FieldSpec('whatsapp', 'WhatsApp numarası (isteğe bağlı)', initial: _phoneText(b?['whatsapp']),
            validator: phoneValidator, keyboard: TextInputType.phone),
        FieldSpec('website', 'Web sitesi (isteğe bağlı)', initial: b?['website'] as String?,
            validator: httpsValidator, hint: 'https:// ile başlamalı'),
        FieldSpec('instagram', 'Instagram adresi (isteğe bağlı)', initial: b?['instagram'] as String?,
            validator: httpsValidator, hint: 'Ör. https://instagram.com/isletme'),
        FieldSpec('address', 'Adres (isteğe bağlı)', initial: b?['address'] as String?),
        FieldSpec('latitude', 'Enlem (isteğe bağlı)', initial: b?['latitude']?.toString(),
            validator: numberValidator(min: 40, max: 41), hint: 'Yol tarifi için. Ör. 40.3991'),
        FieldSpec('longitude', 'Boylam (isteğe bağlı)', initial: b?['longitude']?.toString(),
            validator: numberValidator(min: 27, max: 28.5)),
      ],
    );
    if (v == null) return;
    final lat = parseNumber(v['latitude']!);
    final lng = parseNumber(v['longitude']!);
    if ((lat == null) != (lng == null)) {
      _toast('Enlem ve boylam birlikte girilmeli.');
      return;
    }
    String? opt(String key) => v[key]!.isEmpty ? null : v[key];
    final phone = opt('phone');
    final whatsapp = opt('whatsapp');
    final item = <String, dynamic>{
      'id': b?['id'] ?? newId('isl'),
      'name': v['name'],
      'categoryId': v['categoryId'],
      'summary': ?opt('summary'),
      'description': ?opt('description'),
      'hours': ?opt('hours'),
      'phone': ?(phone == null ? null : normalizePhone(phone)),
      'whatsapp': ?(whatsapp == null ? null : normalizePhone(whatsapp)),
      'website': ?opt('website'),
      'instagram': ?opt('instagram'),
      'address': ?opt('address'),
      'latitude': ?lat,
      'longitude': ?lng,
      // Fotoğraflar kartın altında yönetilir; korunur.
      if ((b?['photos'] as List<dynamic>?)?.isNotEmpty ?? false) 'photos': b!['photos'],
    };
    _apply(() {
      if (b == null) {
        _businesses.add(item);
      } else {
        _businesses[_businesses.indexOf(b)] = item;
      }
    });
  }

  static String? _phoneText(Object? phone) => phone == null ? null : formatPhone(phone as String);

  List<dynamic> _photosOf(Map<String, dynamic> b) => b.putIfAbsent('photos', () => <dynamic>[]) as List<dynamic>;

  Future<void> _addPhoto(Map<String, dynamic> b) async {
    if (_photosOf(b).length >= _maxPhotos) {
      _toast('Bir işletmeye en fazla $_maxPhotos fotoğraf eklenebilir.');
      return;
    }
    final picked = await pickImage();
    if (picked == null) return;
    if (picked.bytes.length > _maxPhotoBytes) {
      _toast('Fotoğraf 2 MB\'tan büyük (${(picked.bytes.length / 1024).round()} KB). Küçültüp tekrar deneyin.');
      return;
    }
    if (!mounted) return;
    final v = await showFormDialog(
      context,
      title: 'Fotoğraf bilgisi',
      fields: const [
        FieldSpec(
          'credit',
          'Fotoğraf sahibi / kaynak (isteğe bağlı)',
          hint: 'Yalnızca işletmenin izin verdiği / kullanım hakkı olan fotoğrafları yükleyin.',
        ),
      ],
    );
    if (v == null) return;
    setState(() => _uploadingFor = b['id'] as String);
    try {
      final url = await widget.api.uploadContentImage(picked.bytes, contentType: picked.type, folder: 'businesses');
      _apply(() => _photosOf(b).add(<String, dynamic>{
            'url': url,
            if (v['credit']!.isNotEmpty) 'credit': v['credit'],
          }));
      _toast('Fotoğraf yüklendi. Yayına almak için "Kaydet"e basın.');
    } catch (e) {
      _toast('Fotoğraf yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _uploadingFor = null);
    }
  }

  void _removePhoto(Map<String, dynamic> b, int index) => _apply(() {
        final photos = _photosOf(b)..removeAt(index);
        if (photos.isEmpty) b.remove('photos');
      });

  @override
  Widget build(BuildContext context) {
    final categories = _categories.cast<Map<String, dynamic>>();
    final names = _categoryOptions;
    final all = _businesses.cast<Map<String, dynamic>>();
    final shown = [for (final b in all) if (_filter == null || b['categoryId'] == _filter) b];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Kategoriler
        AdminSectionTitle(
          'Kategoriler',
          subtitle: 'Uygulamada işletmelerin üstünde filtre olarak görünür (boş kategori gösterilmez).',
          trailing: FilledButton.tonalIcon(
            onPressed: () => _editCategory(),
            icon: const Icon(Icons.add),
            label: const Text('Kategori ekle'),
          ),
        ),
        Card(
          child: Column(
            children: [
              if (categories.isEmpty)
                const Padding(padding: EdgeInsets.all(20), child: Text('Henüz kategori yok.')),
              for (var i = 0; i < categories.length; i++) ...[
                if (i > 0) const Divider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AdminColors.background,
                    child: Icon(_iconData[categories[i]['icon']] ?? Icons.storefront_outlined, color: AdminColors.blue),
                  ),
                  title: Text(categories[i]['title'] as String),
                  subtitle: Text('${_countIn(categories[i]['id'] as String)} işletme'),
                  trailing: RowActions(
                    onUp: i > 0 ? () => _apply(() => moveItem(_categories, i, -1)) : null,
                    onDown: i < categories.length - 1 ? () => _apply(() => moveItem(_categories, i, 1)) : null,
                    onEdit: () => _editCategory(categories[i]),
                    onDelete: () => _deleteCategory(i),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── İşletmeler
        AdminSectionTitle(
          'İşletmeler (${all.length})',
          subtitle: 'Yalnızca bilgileri doğrulanmış ve izin alınmış işletmeleri ekleyin.',
          trailing: FilledButton.icon(
            onPressed: () => _editBusiness(),
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('İşletme ekle'),
          ),
        ),
        if (categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text('Tümü (${all.length})'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                for (final c in categories)
                  ChoiceChip(
                    label: Text('${c['title']} (${_countIn(c['id'] as String)})'),
                    selected: _filter == c['id'],
                    onSelected: (_) => setState(() => _filter = c['id'] as String),
                  ),
              ],
            ),
          ),
        if (shown.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Bu listede işletme yok. "İşletme ekle" ile başlayın.'),
            ),
          ),
        for (final b in shown)
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                  title: Text(b['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    [
                      names[b['categoryId']] ?? '⚠ Kategori seçilmemiş',
                      if (b['summary'] != null) b['summary'] as String,
                      if (b['phone'] != null) formatPhone(b['phone'] as String),
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: RowActions(
                    // Sıralama yalnızca tüm liste görünürken (süzgeçte sıra karışmasın).
                    onUp: _filter == null && all.indexOf(b) > 0
                        ? () => _apply(() => moveItem(_businesses, all.indexOf(b), -1))
                        : null,
                    onDown: _filter == null && all.indexOf(b) < all.length - 1
                        ? () => _apply(() => moveItem(_businesses, all.indexOf(b), 1))
                        : null,
                    onEdit: () => _editBusiness(b),
                    onDelete: () async {
                      if (await confirmDelete(context, 'İşletme')) _apply(() => _businesses.remove(b));
                    },
                  ),
                ),
                PhotoStrip(
                  photos: (b['photos'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>(),
                  uploading: _uploadingFor == b['id'],
                  onAdd: _uploadingFor == null ? () => _addPhoto(b) : null,
                  onRemove: (index) async {
                    if (await confirmDelete(context, 'Fotoğraf')) _removePhoto(b, index);
                  },
                  onMakeCover: (index) => _apply(() => moveItem(_photosOf(b), index, -index)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
