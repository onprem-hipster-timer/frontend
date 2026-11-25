import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/current_task_display.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../sample_provider_scope.dart';
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
  final paused = knobs.boolean(
    label: '일시정지',
    description: '일시정지 중에는 할 일 상태 아이콘을 눌러 그 자리에서 상태를 바꿀 수 있다',
  );
  final friend = knobs.boolean(
    label: '친구 타이머',
    description: '친구가 공유한 타이머는 공유 설정 버튼이 없다',
  );
  // 앱에서는 대시보드 양옆 24 여백 안, 다이얼 위 가운데 줄이다
  return SampleProviderScope(
    // 제목 뒤 공유 설정 버튼을 누르면 시트가 열린다
    overrides: sampleShareOverrides(sampleTimer()),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: hasTimer
            ? _Task(
                // 노브를 바꾸면 누른 상태를 버리고 노브 값으로 돌아간다
                key: ValueKey(todoStatus),
                title: title,
                todoStatus: todoStatus,
                paused: paused,
                friend: friend,
              )
            : const CurrentTaskDisplay(timer: null),
      ),
    ),
  );
}

/// 일시정지 중에 고른 할 일 상태가 보이도록 그 상태를 여기서 가진다
class _Task extends StatefulWidget {
  const _Task({
    super.key,
    required this.title,
    required this.todoStatus,
    required this.paused,
    required this.friend,
  });

  final String title;
  final TodoStatus? todoStatus;
  final bool paused;
  final bool friend;

  @override
  State<_Task> createState() => _TaskState();
}

class _TaskState extends State<_Task> {
  late var _status = widget.todoStatus;

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return CurrentTaskDisplay(
      timer: sampleTimer(
        title: widget.title,
        status: widget.paused ? TimerStatus.paused : TimerStatus.running,
        todo: status == null
            ? null
            : sampleTodo(title: widget.title, status: status),
        isShared: widget.friend,
      ),
      onTodoStatusSelected: (status) => setState(() => _status = status),
    );
  }
}
