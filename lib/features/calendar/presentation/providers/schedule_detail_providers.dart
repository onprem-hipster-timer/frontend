import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';

part 'schedule_detail_providers.g.dart';

// ============================================================
// 일정 상세 Provider (단건 조회, 타이머)
// ============================================================

/// 일정 단건 조회 (mutation 후 반응형 업데이트용)
@riverpod
Future<ScheduleRead> scheduleDetail(Ref ref, String scheduleId) async {
  final api = ref.watch(schedulesApiProvider);
  return api.readScheduleV1SchedulesScheduleIdGet(scheduleId: scheduleId);
}

/// 일정별 타이머 목록
@riverpod
Future<List<TimerRead>> scheduleTimers(Ref ref, String scheduleId) async {
  final api = ref.watch(schedulesApiProvider);
  return api.getScheduleTimersV1SchedulesScheduleIdTimersGet(
    scheduleId: scheduleId,
  );
}
