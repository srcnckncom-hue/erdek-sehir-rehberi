import 'package:dio/dio.dart';

import '../data/json_sources.dart';

/// `<DATA_BASE_URL>/data/<path>` adresinden JSON metnini indirir.
class DioJsonFetcher implements JsonFetcher {
  DioJsonFetcher(this._dio, {required String baseUrl})
      : _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

  final Dio _dio;
  final String _baseUrl;

  @override
  Future<String> fetch(String path) async {
    if (_baseUrl == '/') {
      throw StateError('DATA_BASE_URL tanımlı değil.');
    }
    final response = await _dio.get<String>(
      '${_baseUrl}data/$path',
      options: Options(responseType: ResponseType.plain),
    );
    final body = response.data;
    if (body == null || body.isEmpty) {
      throw StateError('Boş yanıt: $path');
    }
    return body;
  }
}
