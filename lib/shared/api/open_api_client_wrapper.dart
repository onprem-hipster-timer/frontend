/// OpenAPI Client Wrapper
/// 생성된 OpenAPI 클라이언트의 래퍼 역할을 수행합니다.
///
/// 사용 예시:
/// ```dart
/// final client = OpenApiClientWrapper('https://api.example.com', 'your-token');
/// final schedules = await client.schedulesApi.readSchedules(...);
/// ```

import 'package:dio/dio.dart';
import 'package:momeet/shared/api/generated/lib/openapi_client.dart';

class OpenApiClientWrapper {
  late final Dio _dio;
  late final OpenAPIClient _client;

  /// HTTP Client API
  late final SchedulesApi _schedulesApi;

  /// Timer API
  late final TimersApi _timersApi;

  /// Tags API
  late final TagsApi _tagsApi;

  /// Todos API
  late final TodosApi _todosApi;

  /// Friends API
  late final FriendsApi _friendsApi;

  /// Holidays API
  late final HolidaysApi _holidaysApi;

  OpenApiClientWrapper({
    required String baseUrl,
    String? authToken,
    Dio? dio,
  }) {
    _dio = dio ?? Dio();

    // Configure Dio
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add authentication if token is provided
    if (authToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $authToken';
    }

    // Initialize OpenAPI client
    _client = OpenAPIClient(basePath: baseUrl, dio: _dio);

    // Initialize API instances
    _schedulesApi = SchedulesApi(_dio, basePath: baseUrl);
    _timersApi = TimersApi(_dio, basePath: baseUrl);
    _tagsApi = TagsApi(_dio, basePath: baseUrl);
    _todosApi = TodosApi(_dio, basePath: baseUrl);
    _friendsApi = FriendsApi(_dio, basePath: baseUrl);
    _holidaysApi = HolidaysApi(_dio, basePath: baseUrl);
  }

  /// Set or update the authentication token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear the authentication token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // API Accessors
  SchedulesApi get schedulesApi => _schedulesApi;
  TimersApi get timersApi => _timersApi;
  TagsApi get tagsApi => _tagsApi;
  TodosApi get todosApi => _todosApi;
  FriendsApi get friendsApi => _friendsApi;
  HolidaysApi get holidaysApi => _holidaysApi;

  /// Get the underlying Dio instance for advanced usage
  Dio get dio => _dio;

  /// Get the underlying OpenAPI client
  OpenAPIClient get client => _client;
}
