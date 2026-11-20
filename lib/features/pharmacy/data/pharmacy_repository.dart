import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_result.dart';
import '../../../core/data/offline_first_loader.dart';
import '../domain/pharmacy.dart';

/// Nöbetçi eczane verisinin kaynağı. Şimdilik GitHub Pages'teki elle
/// hazırlanan JSON; ileride bir API'ye geçilirse yalnızca bu arayüzün
/// yeni bir uygulaması yazılır.
abstract interface class PharmacyRepository {
  Stream<DataResult<PharmacyData>> watch();
}

class JsonPharmacyRepository implements PharmacyRepository {
  JsonPharmacyRepository(this._loader);

  static const path = 'pharmacy.json';

  final OfflineFirstLoader _loader;

  @override
  Stream<DataResult<PharmacyData>> watch() =>
      _loader.watch(path, PharmacyData.fromJson);
}

final pharmacyRepositoryProvider = Provider<PharmacyRepository>(
  (ref) => JsonPharmacyRepository(ref.watch(offlineFirstLoaderProvider)),
);

final pharmacyDataProvider = StreamProvider<DataResult<PharmacyData>>(
  (ref) => ref.watch(pharmacyRepositoryProvider).watch(),
);
