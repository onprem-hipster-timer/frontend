import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/info_row.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

typedef _Row = ({
  IconData icon,
  String label,
  String value,
  String longValue,
  bool multiline,
});

const _rows = <String, _Row>{
  '시간': (
    icon: Icons.access_time,
    label: '시간',
    value: '2026년 03월 02일 (월)\n10:00 ~ 12:00',
    longValue: '2026년 03월 02일 10:00 ~\n2026년 03월 04일 18:00',
    multiline: false,
  ),
  '설명': (
    icon: Icons.description,
    label: '설명',
    value: '회의실 B에서 분기 계획을 함께 봅니다.',
    longValue:
        '회의실 B에서 분기 계획을 함께 봅니다. 지난 분기 회고 자료와 이번 분기 목표 초안을 '
        '미리 읽어 오고, 발표 순서는 모모, 토끼, 곰돌이 순으로 합니다. 끝나고 점심을 같이 먹어요.',
    multiline: true,
  ),
  '반복': (
    icon: Icons.repeat,
    label: '반복',
    value: '매주 (월, 수)',
    longValue: '2주마다 (월, 화, 수, 목, 금, 토, 일)',
    multiline: false,
  ),
  '생성': (
    icon: Icons.schedule,
    label: '생성',
    value: '2026.02.20 09:30',
    longValue: '2026.02.20 09:30',
    multiline: false,
  ),
};

@widgetbook.UseCase(name: '일정 정보 줄', type: InfoRow, path: '[달력]')
Widget infoRow(BuildContext context) {
  final knobs = context.knobs;
  final kind = knobs.object.dropdown(
    label: '항목',
    description: '일정 상세 화면에 쌓이는 줄. 설명은 이름표 아래에 내용을 둔다',
    options: _rows.keys.toList(),
  );
  final long = knobs.boolean(label: '긴 내용');
  final row = _rows[kind]!;
  // 일정 상세 화면의 본문 여백
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: InfoRow(
      icon: row.icon,
      label: row.label,
      value: long ? row.longValue : row.value,
      isMultiline: row.multiline,
    ),
  );
}
