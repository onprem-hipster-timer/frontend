import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/current_task_display.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_timer.dart';

@widgetbook.UseCase(name: '타이머 작업 제목', type: CurrentTaskDisplay, path: '[타이머]')
Widget currentTaskDisplay(BuildContext context) {
  final knobs = context.knobs;
  final hasTimer = knobs.boolean(
    label: '진행 중인 타이머',
    initialValue: true,
    description: '없으면 대시보드 위에 안내 문구를 둔다',
  );
  final title = knobs.string(label: '제목', initialValue: '보고서 초안 쓰기');
  final todoStatus = knobs.object
      .dropdown(
        label: '연결한 할 일',
        options: <(String, TodoStatus?)>[
          ('없음', null),
          for (final status in const [
            TodoStatus.unscheduled,
            TodoStatus.scheduled,
            TodoStatus.done,
            TodoStatus.cancelled,
          ])
            ('${status.label} 상태', status),
        ],
        labelBuilder: (option) => option.$1,
        description: '할 일에서 시작한 타이머는 제목 앞에 할 일 상태를 둔다',
      )
      .$2;
  final friend = knobs.boolean(
    label: '친구 타이머',
    description: '친구가 공유한 타이머는 공유 설정 버튼이 없다',
  );
  // 앱에서는 대시보드 양옆 24 여백 안, 다이얼 위 가운데 줄이다
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Align(
      alignment: Alignment.topCenter,
      child: CurrentTaskDisplay(
        timer: hasTimer
            ? sampleTimer(
                title: title,
                todo: todoStatus == null
                    ? null
                    : sampleTodo(title: title, status: todoStatus),
                isShared: friend,
              )
            : null,
      ),
    ),
  );
}
