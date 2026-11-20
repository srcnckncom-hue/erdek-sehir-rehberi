import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_result.dart';
import '../../../core/data/offline_first_loader.dart';
import '../domain/contacts.dart';

abstract interface class ContactsRepository {
  Stream<DataResult<ContactsData>> watch();
}

class JsonContactsRepository implements ContactsRepository {
  JsonContactsRepository(this._loader);

  static const path = 'contacts.json';

  final OfflineFirstLoader _loader;

  @override
  Stream<DataResult<ContactsData>> watch() =>
      _loader.watch(path, ContactsData.fromJson);
}

final contactsRepositoryProvider = Provider<ContactsRepository>(
  (ref) => JsonContactsRepository(ref.watch(offlineFirstLoaderProvider)),
);

final contactsDataProvider = StreamProvider<DataResult<ContactsData>>(
  (ref) => ref.watch(contactsRepositoryProvider).watch(),
);
