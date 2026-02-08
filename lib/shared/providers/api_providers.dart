// API 클라이언트 프로바이더들
//
// OpenAPI 자동 생성된 API 클래스들을 Riverpod Provider로 감싸서 제공합니다.
// 각 Provider는 Dio 인스턴스를 주입받아 API 클라이언트를 생성합니다.

import 'package:built_value/serializer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/dio_provider.dart';
import 'package:momeet_api/momeet_api.dart';

// ============================================================
// Serializers 프로바이더
// ============================================================

/// 공유 Serializers 인스턴스
///
/// OpenAPI 생성 모델들의 JSON 직렬화/역직렬화에 사용됩니다.
final serializersProvider = Provider<Serializers>((ref) {
  return standardSerializers;
});

// ============================================================
// API 클라이언트 Providers
// ============================================================

/// Schedules API 클라이언트
///
/// 사용 예:
/// ```dart
/// final api = ref.watch(schedulesApiProvider);
/// final schedules = await api.readSchedulesV1SchedulesGet();
/// ```
final schedulesApiProvider = Provider<SchedulesApi>((ref) {
  final dio = ref.watch(dioClientProvider);
  final serializers = ref.watch(serializersProvider);
  return SchedulesApi(dio, serializers);
});

/// Todos API 클라이언트
///
/// 사용 예:
/// ```dart
/// final api = ref.watch(todosApiProvider);
/// final todos = await api.readTodosV1TodosGet();
/// ```
final todosApiProvider = Provider<TodosApi>((ref) {
  final dio = ref.watch(dioClientProvider);
  final serializers = ref.watch(serializersProvider);
  return TodosApi(dio, serializers);
});

/// Tags API 클라이언트
///
/// 사용 예:
/// ```dart
/// final api = ref.watch(tagsApiProvider);
/// final tags = await api.readTagsV1TagsGet();
/// ```
final tagsApiProvider = Provider<TagsApi>((ref) {
  final dio = ref.watch(dioClientProvider);
  final serializers = ref.watch(serializersProvider);
  return TagsApi(dio, serializers);
});

/// Timers API 클라이언트
///
/// 사용 예:
/// ```dart
/// final api = ref.watch(timersApiProvider);
/// final timers = await api.readTimersV1TimersGet();
/// ```
final timersApiProvider = Provider<TimersApi>((ref) {
  final dio = ref.watch(dioClientProvider);
  final serializers = ref.watch(serializersProvider);
  return TimersApi(dio, serializers);
});

/// Holidays API 클라이언트
///
/// 사용 예:
/// ```dart
/// final api = ref.watch(holidaysApiProvider);
/// final holidays = await api.getHolidaysV1HolidaysYearGet(year: 2024);
/// ```
final holidaysApiProvider = Provider<HolidaysApi>((ref) {
  final dio = ref.watch(dioClientProvider);
  final serializers = ref.watch(serializersProvider);
  return HolidaysApi(dio, serializers);
});

/// Friends API 클라이언트 (향후 소셜 기능용)
final friendsApiProvider = Provider<FriendsApi>((ref) {
  final dio = ref.watch(dioClientProvider);
  final serializers = ref.watch(serializersProvider);
  return FriendsApi(dio, serializers);
});

/// GraphQL API 클라이언트 (향후 사용 가능)
final graphQlApiProvider = Provider<GraphQLApi>((ref) {
  final dio = ref.watch(dioClientProvider);
  final serializers = ref.watch(serializersProvider);
  return GraphQLApi(dio, serializers);
});

/// Health Check API 클라이언트
final healthApiProvider = Provider<HealthApi>((ref) {
  final dio = ref.watch(dioClientProvider);
  final serializers = ref.watch(serializersProvider);
  return HealthApi(dio, serializers);
});
