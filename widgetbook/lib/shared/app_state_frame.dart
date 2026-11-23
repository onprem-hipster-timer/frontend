import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/components/app_state_frame.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '가운데 안내 틀', type: AppStateFrame, path: '[공통]/상태 안내')
Widget appStateFrame(BuildContext context) {
  final knobs = context.knobs;
  final long = knobs.boolean(
    label: '긴 내용',
    description: '빈 화면·불러오기 실패 안내를 담는 틀. 화면보다 길면 가운데 두지 않고 굴린다',
  );
  final bounded = knobs.boolean(
    label: '높이가 정해진 자리',
    description: '끄면 목록 안처럼 높이 제한 없는 자리라 내용 높이만큼만 차지한다',
    initialValue: true,
  );
  final theme = Theme.of(context);
  final frame = AppStateFrame(
    children: [
      Icon(
        Icons.event_busy_outlined,
        size: 64,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      const SizedBox(height: 16),
      Text(
        '이번 주에는 일정이 없습니다',
        style: theme.textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        long
            ? List.filled(12, '새 일정을 추가하면 이곳에 날짜순으로 보입니다.').join(' ')
            : '새 일정을 추가하면 이곳에 날짜순으로 보입니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );
  if (bounded) return frame;
  return SingleChildScrollView(
    child: Column(
      children: [
        const ListTile(title: Text('목록의 다른 줄')),
        frame,
        const ListTile(title: Text('목록의 다른 줄')),
      ],
    ),
  );
}
