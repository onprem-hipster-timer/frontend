import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '선택 입력 칸', type: AppPickerField, path: '[공통]/입력 양식')
Widget appPickerField(BuildContext context) {
  final knobs = context.knobs;
  final label = knobs.string(label: '이름표', initialValue: '마감일');
  final value = knobs.stringOrNull(
    label: '고른 값',
    description: '비우면 안내 문구를 흐리게 보인다',
    initialValue: '2026년 3월 2일',
  );
  final placeholder = knobs.stringOrNull(
    label: '안내 문구',
    initialValue: '선택 안 함',
  );
  final icon = knobs.boolean(label: '앞 아이콘', initialValue: true);
  final clear = knobs.boolean(
    label: '지우기 버튼',
    description: '마감일처럼 비워 둘 수 있는 칸은 값이 있을 때 펼침 화살표 대신 지우기 버튼을 둔다',
    initialValue: true,
  );
  final enabled = knobs.boolean(
    label: '누를 수 있음',
    description: '끄면 흐려진다(목록을 불러오기 전 등)',
    initialValue: true,
  );
  final error = knobs.stringOrNull(
    label: '오류 문구',
    description: '예: 종료 시간은 시작 시간보다 늦어야 합니다',
  );
  // 앱에서는 입력 시트 안, 좌우 여백 24 안쪽에 놓인다
  return ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppPickerField(
          label: label,
          value: value,
          placeholder: placeholder,
          icon: icon ? Icons.calendar_today : null,
          onTap: enabled ? () {} : null,
          onClear: clear ? () {} : null,
          errorText: error,
        ),
      ),
    ),
  );
}
