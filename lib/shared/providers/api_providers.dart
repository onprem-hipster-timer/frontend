// 개별 API 클라이언트 프로바이더
//
// [moMeetClientProvider]에서 파생합니다.
// 단일 MoMeetClient 인스턴스가 내부적으로 lazy 초기화하므로
// Dio 인스턴스를 중복 생성하지 않습니다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/shared_providers.dart';

final schedulesApiProvider = Provider<SchedulesClient>((ref) {
  return ref.watch(moMeetClientProvider).schedules;
});

final todosApiProvider = Provider<TodosClient>((ref) {
  return ref.watch(moMeetClientProvider).todos;
});

final tagsApiProvider = Provider<TagsClient>((ref) {
  return ref.watch(moMeetClientProvider).tags;
});

final timersApiProvider = Provider<TimersClient>((ref) {
  return ref.watch(moMeetClientProvider).timers;
});

final holidaysApiProvider = Provider<HolidaysClient>((ref) {
  return ref.watch(moMeetClientProvider).holidays;
});

final friendsApiProvider = Provider<FriendsClient>((ref) {
  return ref.watch(moMeetClientProvider).friends;
});

final graphQlApiProvider = Provider<GraphQlClient>((ref) {
  return ref.watch(moMeetClientProvider).graphQl;
});

final healthApiProvider = Provider<HealthClient>((ref) {
  return ref.watch(moMeetClientProvider).health;
});
