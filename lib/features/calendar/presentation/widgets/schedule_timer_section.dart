import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_timer_section_view.dart';

/// 일정에 연결된 타이머 목록을 표시하는 섹션. 모양은 [ScheduleTimerSectionView]
///
/// 자체적으로 [scheduleTimersProvider]를 watch하므로
/// 부모 위젯과 독립적으로 로딩/에러 상태를 처리합니다.
class ScheduleTimerSection extends ConsumerWidget {
  final String scheduleId;

  const ScheduleTimerSection({super.key, required this.scheduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScheduleTimerSectionView(
      timers: ref.watch(scheduleTimersProvider(scheduleId)),
      now: ref.watch(serverClockProvider).now(),
    );
  }
}
