import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/transport.dart';

/// Ulaşım sekmesinde seçili tür (feribot/otobüs), hat ve gün.
/// Ana sayfadaki "Otobüs Saatleri" kutucuğu sekmeyi doğrudan otobüste açabilsin
/// diye ekran dışında (Riverpod'da) tutulur.
@immutable
class TransportSelection {
  const TransportSelection({this.mode = TransportMode.ferry, this.routeId, this.dayOffset = 0});

  final TransportMode mode;

  /// null = bu türün ilk hattı
  final String? routeId;

  /// 0 = bugün, 1 = yarın ... 6
  final int dayOffset;

  TransportSelection copyWith({TransportMode? mode, String? routeId, int? dayOffset}) =>
      TransportSelection(
        mode: mode ?? this.mode,
        routeId: routeId ?? this.routeId,
        dayOffset: dayOffset ?? this.dayOffset,
      );
}

final transportSelectionProvider =
    NotifierProvider<TransportSelectionNotifier, TransportSelection>(
  TransportSelectionNotifier.new,
);

class TransportSelectionNotifier extends Notifier<TransportSelection> {
  @override
  TransportSelection build() => const TransportSelection();

  /// Tür değişince hat seçimi sıfırlanır (o türün ilk hattı).
  void selectMode(TransportMode mode) {
    if (mode == state.mode) return;
    state = TransportSelection(mode: mode, dayOffset: state.dayOffset);
  }

  void selectRoute(String routeId) => state = state.copyWith(routeId: routeId);

  void selectDay(int offset) => state = state.copyWith(dayOffset: offset);
}
