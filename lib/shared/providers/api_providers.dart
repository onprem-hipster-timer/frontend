// API 클라이언트 프로바이더들
//
// swagger_parser로 자동 생성된 API 클래스들을 Riverpod Provider로 감싸서 제공합니다.
// 각 Provider는 Dio 인스턴스를 주입받아 API 클라이언트를 생성합니다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/dio_provider.dart';
import 'package:momeet/shared/api/export.dart';

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
final schedulesApiProvider = Provider<SchedulesClient>((ref) {
  final dio = ref.watch(dioClientProvider);
  return SchedulesClient(dio);
});

/// Todos API 클라이언트
///
/// 사용 예:
/// ```dart
/// final api = ref.watch(todosApiProvider);
/// final todos = await api.readTodosV1TodosGet();
/// ```
final todosApiProvider = Provider<TodosClient>((ref) {
  final dio = ref.watch(dioClientProvider);
  return TodosClient(dio);
});

/// Tags API 클라이언트
///
/// 사용 예:
/// ```dart
/// final api = ref.watch(tagsApiProvider);
/// final tags = await api.readTagsV1TagsGet();
/// ```
final tagsApiProvider = Provider<TagsClient>((ref) {
  final dio = ref.watch(dioClientProvider);
  return TagsClient(dio);
});

/// Timers API 클라이언트
///
/// 사용 예:
/// ```dart
/// final api = ref.watch(timersApiProvider);
/// final timers = await api.readTimersV1TimersGet();
/// ```
final timersApiProvider = Provider<TimersClient>((ref) {
  final dio = ref.watch(dioClientProvider);
  return TimersClient(dio);
});

/// Holidays API 클라이언트
///
/// 사용 예:
/// ```dart
/// final api = ref.watch(holidaysApiProvider);
/// final holidays = await api.getHolidaysV1HolidaysYearGet(year: 2024);
/// ```
final holidaysApiProvider = Provider<HolidaysClient>((ref) {
  final dio = ref.watch(dioClientProvider);
  return HolidaysClient(dio);
});

/// Friends API 클라이언트 (향후 소셜 기능용)
final friendsApiProvider = Provider<FriendsClient>((ref) {
  final dio = ref.watch(dioClientProvider);
  return FriendsClient(dio);
});

/// GraphQL API 클라이언트 (향후 사용 가능)
final graphQlApiProvider = Provider<GraphQlClient>((ref) {
  final dio = ref.watch(dioClientProvider);
  return GraphQlClient(dio);
});

/// Health Check API 클라이언트
final healthApiProvider = Provider<HealthClient>((ref) {
  final dio = ref.watch(dioClientProvider);
  return HealthClient(dio);
});
