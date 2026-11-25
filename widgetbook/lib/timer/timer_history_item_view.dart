import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_history_item_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../sample_provider_scope.dart';
import 'samples_timer.dart';

/// 목록 항목이 보이는 타이머 상태. 노브 선택지로 쓴다
enum _State {
  running('진행 중', TimerStatus.running),
  paused('일시정지', TimerStatus.paused),
  timeUp('시간 종료', TimerStatus.paused),
  completed('완료', TimerStatus.completed),
  cancelled('취소', TimerStatus.cancelled);

  const _State(this.label, this.status);

  final String label;
  final TimerStatus status;
}

@widgetbook.UseCase(
  name: '타이머 목록 항목',
  type: TimerHistoryItemView,
  path: '[타이머]',
)
Widget timerHistoryItemView(BuildContext context) {
  final knobs = context.knobs;
  final state = knobs.object.dropdown(
    label: '상태',
    options: _State.values,
    labelBuilder: (state) => state.label,
    description: '진행 중·일시정지는 남은 시간과 조작 버튼을, 시간 종료는 일시정지·재개 대신 5분 연장을 둔다',
  );
  final minutes = knobs.int.slider(
    label: '보이는 시간(분)',
    description: '진행 중·일시정지는 남은 시간, 끝난 타이머는 집중한 시간',
    initialValue: 12,
    max: 180,
    divisions: 180,
  );
  final long = knobs.boolean(label: '긴 제목');
  final timer =
      sampleTimer(
        status: state.status,
        title: long ? '토익 모의고사 2회분 풀고 틀린 문제 오답 노트에 정리하기' : null,
        visibilityLevel: VisibilityLevel.friends,
      ).copyWith(
        endedAt: switch (state) {
          _State.completed ||
          _State.cancelled => DateTime.utc(2026, 3, 2, 9, 25),
          _ => null,
        },
      );
  // 앱에서는 타이머 목록의 내 타이머 탭에, 날짜 머리말 아래 좌우 16 여백 안에 줄지어 놓인다.
  // 폭이 모자라면 시간과 버튼을 제목 아래 줄로 내린다. 공유 설정 버튼을 누르면 시트가 열린다
  return SampleProviderScope(
    overrides: sampleShareOverrides(timer),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: TimerHistoryItemView(
        timer: timer,
        duration: state == _State.timeUp
            ? Duration.zero
            : Duration(minutes: minutes, seconds: 34),
        timeUp: state == _State.timeUp,
        onExtend: () {},
        onPause: () {},
        onResume: () {},
        onStop: () {},
      ),
    ),
  );
}
