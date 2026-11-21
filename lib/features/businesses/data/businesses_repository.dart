import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_result.dart';
import '../domain/business.dart';

/// İşletmeler (data/businesses.json; panelden düzenlenir).
/// Diğer veriler gibi: önbellek → uygulamayla gelen kopya → Supabase / Pages.
final businessesDataProvider = StreamProvider<DataResult<BusinessesData>>(
  (ref) => ref.watch(offlineFirstLoaderProvider).watch('businesses.json', BusinessesData.fromJson),
);
