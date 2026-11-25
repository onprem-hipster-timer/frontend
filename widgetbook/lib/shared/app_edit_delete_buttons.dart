import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '수정·삭제 버튼',
  type: AppEditDeleteButtons,
  path: '[공통]/버튼·확인 창',
)
Widget appEditDeleteButtons(BuildContext context) {
  final width = context.knobs.double.slider(
    label: '놓인 자리 폭',
    description: '태그·할 일 줄 끝에 둔다. 두 버튼이 한 줄에 안 들어가면 삭제가 다음 줄 오른쪽으로 내려간다',
    initialValue: 200,
    min: 100,
    max: 328,
    divisions: 57,
    precision: 0,
  );
  final disabled = context.knobs.boolean(
    label: '누를 수 없음',
    description: '보이기만 하고 누를 수 없을 때. 삭제도 오류색 대신 흐린 모양이다',
  );
  return Center(
    child: Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: AppRadius.mdAll,
      ),
      child: AppEditDeleteButtons(
        itemName: '운동 태그',
        onEdit: disabled ? null : () {},
        onDelete: disabled ? null : () {},
      ),
    ),
  );
}
