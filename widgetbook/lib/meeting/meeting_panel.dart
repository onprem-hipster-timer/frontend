import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_quiet_panels.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '모임 화면 상자', type: MeetingPanel, path: '[모임]/화면 틀')
Widget meetingPanel(BuildContext context) {
  final knobs = context.knobs;
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final highlighted =
      knobs.object.dropdown(
        label: '상자',
        description: '추천 시간 상자는 바탕을 강조 색으로 칠하고 제목 옆에 도움말 물음표를 둔다',
        options: const ['일정 참여자', '추천 시간'],
      ) ==
      '추천 시간';
  final trailing = knobs.boolean(
    label: '오른쪽 끝 버튼',
    description: '제목과 함께 한 줄에 들어가지 않으면 다음 줄로 내려간다',
    initialValue: true,
  );
  final quiet = knobs.boolean(
    label: '조용한 모양',
    description: '좁은 화면 끝의 일정 참여자·링크처럼 상자 없이 작은 제목과 내용만 둔다',
  );
  final ink = highlighted ? scheme.onPrimaryContainer : null;
  final Widget panel = highlighted
      ? MeetingPanel(
          title: '추천 시간',
          help:
              '여러 사람이 함께 되는 시간을 보여 줘요. '
              '모모밋 추천은 사람이 많이 모이면서 오래 되는 시간을 먼저 보여 줘요',
          color: scheme.primaryContainer,
          foreground: ink,
          trailing: trailing
              ? IconButton(
                  tooltip: '모두 복사',
                  visualDensity: VisualDensity.compact,
                  color: ink,
                  icon: const Icon(Icons.copy_all_outlined),
                  onPressed: () {},
                )
              : null,
          child: Text(
            '두 명 이상 함께 되는 시간이 생기면 여기에 추천해 드려요',
            style: theme.textTheme.bodyMedium?.copyWith(color: ink),
          ),
        )
      : MeetingPanel(
          title: '일정 참여자',
          trailing: trailing
              ? TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('편집'),
                )
              : null,
          child: Text('3명 참여 중', style: theme.textTheme.bodyMedium),
        );
  // 앱에서는 모임 화면 옆 칸(좁으면 격자 아래)에 그 폭을 채워 놓인다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: quiet ? MeetingQuietPanels(child: panel) : panel,
  );
}
