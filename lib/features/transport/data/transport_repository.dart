import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_result.dart';
import '../../../core/data/offline_first_loader.dart';
import '../domain/transport.dart';

abstract interface class TransportRepository {
  Stream<DataResult<TransportData>> watch();
}

class JsonTransportRepository implements TransportRepository {
  JsonTransportRepository(this._loader);

  static const path = 'transport.json';

  final OfflineFirstLoader _loader;

  @override
  Stream<DataResult<TransportData>> watch() =>
      _loader.watch(path, TransportData.fromJson);
}

final transportRepositoryProvider = Provider<TransportRepository>(
  (ref) => JsonTransportRepository(ref.watch(offlineFirstLoaderProvider)),
);

final transportDataProvider = StreamProvider<DataResult<TransportData>>(
  (ref) => ref.watch(transportRepositoryProvider).watch(),
);
