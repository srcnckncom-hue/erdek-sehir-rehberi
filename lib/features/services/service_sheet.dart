import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/launch_or_notify.dart';
import '../../core/util/launchers.dart';
import '../../l10n/app_localizations.dart';
import '../nearby/points.dart';
import 'map_layers.dart';
import 'services.dart';

/// Hizmet noktası: tür, not, saat; ara ve yol tarifi.
Future<void> openServicePoint(BuildContext context, ServicePoint s) {
  final l10n = AppLocalizations.of(context);
  final layer = MapLayer.values.byName(s.type.name);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final p = sheetContext.palette;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          key: const Key('service_sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: AppIcon(MapLayerStyle.icon(layer), size: 28, color: MapLayerStyle.color(p, layer)),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text([MapLayerStyle.label(l10n, layer), ?s.note].join(' · ')),
            ),
            if (s.hours case final h?)
              ListTile(
                leading: AppIcon(AppIcons.clock, size: 24, color: p.textSecondary),
                title: Text(h),
              ),
            if (s.phone case final phone?)
              ListTile(
                leading: AppIcon(AppIcons.call, size: 24, color: p.mint.foreground),
                title: Text(l10n.call),
                subtitle: Text(Launchers.formatPhone(phone)),
                onTap: () => launchOrNotify(sheetContext, () => Launchers.call(phone)),
              ),
            ListTile(
              key: const Key('service_directions'),
              leading: AppIcon(AppIcons.directions, size: 24, color: p.primary),
              title: Text(l10n.directions),
              onTap: () => launchOrNotify(
                sheetContext,
                () => Launchers.directions(name: s.name, latitude: s.latitude, longitude: s.longitude),
              ),
            ),
          ],
        ),
      );
    },
  );
}
