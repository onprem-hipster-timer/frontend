import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/shared_timer_item_view.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_status_chip.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_timer.dart';

@widgetbook.UseCase(name: '친구 타이머 항목', type: SharedTimerItemView, path: '[타이머]')
Widget sharedTimerItemView(BuildContext context) {
  final knobs = context.knobs;
  final status = knobs.object.dropdown(
    label: '상태',
    options: const [
      TimerStatus.running,
      TimerStatus.paused,
      TimerStatus.completed,
      TimerStatus.cancelled,
    ],
    labelBuilder: (status) => timerStatusStyle(context, status).label,
    description: '진행 중·일시정지는 남은 시간을, 끝난 타이머는 집중한 시간을 보인다',
  );
  final minutes = knobs.int.slider(
    label: '보이는 시간(분)',
    initialValue: 12,
    max: 180,
    divisions: 180,
  );
  final longTitle = knobs.boolean(label: '긴 제목', description: '두 줄까지 보이고 줄인다');
  final longName = knobs.boolean(
    label: '긴 친구 이름',
    description: '상태 옆에 다 들어가지 않으면 다음 줄로 내린다',
  );
  // 앱에서는 타이머 목록의 친구 타이머 탭에, 목록 좌우 16 여백 안에 줄지어 놓인다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: SharedTimerItemView(
      timer: sampleTimer(
        index: 1,
        status: status,
        title: longTitle ? '토익 모의고사 2회분 풀고 틀린 문제 오답 노트에 정리하기' : null,
        isShared: true,
      ),
      ownerName: longName ? '주말마다 같이 공부하는 다람쥐' : '다람쥐',
      duration: Duration(minutes: minutes, seconds: 34),
    ),
  );
}
