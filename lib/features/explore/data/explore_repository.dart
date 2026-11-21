import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_result.dart';
import '../domain/explore.dart';

/// Gezilecek yerler (data/places.json) ve Erdek tarihi (data/history.json).
/// Diğer veriler gibi: önbellek → uygulamayla gelen kopya → GitHub Pages.
final placesDataProvider = StreamProvider<DataResult<PlacesData>>(
  (ref) => ref.watch(offlineFirstLoaderProvider).watch('places.json', PlacesData.fromJson),
);

final historyDataProvider = StreamProvider<DataResult<HistoryData>>(
  (ref) => ref.watch(offlineFirstLoaderProvider).watch('history.json', HistoryData.fromJson),
);
