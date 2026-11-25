import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '취소·저장 버튼 줄',
  type: AppFormActionBar,
  path: '[공통]/입력 양식',
)
Widget appFormActionBar(BuildContext context) {
  final knobs = context.knobs;
  final submitLabel = knobs.string(label: '저장 버튼', initialValue: '생성');
  final cancelLabel = knobs.string(label: '취소 버튼', initialValue: '취소');
  final enabled = knobs.boolean(
    label: '저장 가능',
    description: '끄면 저장을 누를 수 없다(타이머 시간을 비운 때 등)',
    initialValue: true,
  );
  final busy = knobs.boolean(
    label: '저장 중',
    description: '서버에 보내는 동안 두 버튼을 막고 저장 자리에 도는 표시를 둔다',
  );
  // 앱에서는 입력 시트 맨 아래, 좌우·아래 여백 24 안쪽에 놓인다
  return ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppFormActionBar(
          submitLabel: submitLabel,
          cancelLabel: cancelLabel,
          onSubmit: enabled ? () {} : null,
          onCancel: () {},
          busy: busy,
        ),
      ),
    ),
  );
}
