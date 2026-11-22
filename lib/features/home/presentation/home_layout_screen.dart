import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../home_layout.dart';

Future<void> openHomeLayout(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HomeLayoutScreen()),
    );

/// Ana sayfayı düzenle: kutucukları sürükleyerek sırala, anahtarla göster/gizle.
class HomeLayoutScreen extends ConsumerStatefulWidget {
  const HomeLayoutScreen({super.key});

  @override
  ConsumerState<HomeLayoutScreen> createState() => _HomeLayoutScreenState();
}

class _HomeLayoutScreenState extends ConsumerState<HomeLayoutScreen> {
  late List<HomeTile> _order;
  late Set<HomeTile> _on;

  @override
  void initState() {
    super.initState();
    _load(ref.read(homeTilesProvider));
  }

  void _load(List<HomeTile> visible) {
    _on = {...visible};
    _order = [...visible, for (final t in HomeTile.values) if (!_on.contains(t)) t];
  }

  void _save() => unawaited(ref.read(homeTilesProvider.notifier).set([for (final t in _order) if (_on.contains(t)) t]));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final isDefault = ref.watch(homeTilesProvider.notifier).isDefault;

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: l10n.homeLayoutTitle,
            subtitle: l10n.homeLayoutSubtitle(_on.length),
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.back,
            trailing: isDefault
                ? null
                : TextButton(
                    key: const Key('home_layout_reset'),
                    onPressed: () async {
                      await ref.read(homeTilesProvider.notifier).reset();
                      setState(() => _load(HomeTile.defaults));
                    },
                    child: Text(l10n.homeLayoutReset),
                  ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              key: const Key('home_layout_list'),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                MediaQuery.paddingOf(context).bottom + AppSpacing.xxl,
              ),
              buildDefaultDragHandles: false,
              itemCount: _order.length,
              onReorderItem: (from, to) {
                setState(() => _order.insert(to, _order.removeAt(from)));
                _save();
              },
              itemBuilder: (context, i) {
                final t = _order[i];
                final on = _on.contains(t);
                return Padding(
                  key: ValueKey(t),
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Material(
                    color: p.surface,
                    borderRadius: AppRadius.cardAll,
                    child: ListTile(
                      leading: ReorderableDragStartListener(
                        index: i,
                        child: AppIcon(AppIcons.dragHandle, size: 22, color: p.textSecondary),
                      ),
                      title: Row(
                        children: [
                          AppIcon(t.icon, size: 22, color: on ? t.color(p) : p.textSecondary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              t.label(l10n),
                              style: AppTypography.label.copyWith(color: on ? p.textHeading : p.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      trailing: Switch.adaptive(
                        key: Key('home_layout_${t.name}'),
                        value: on,
                        onChanged: (v) {
                          setState(() => v ? _on.add(t) : _on.remove(t));
                          _save();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
