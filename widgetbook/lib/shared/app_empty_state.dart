import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '빈 화면 안내', type: AppEmptyState, path: '[공통]/상태 안내')
Widget appEmptyState(BuildContext context) {
  final knobs = context.knobs;
  return AppEmptyState(
    icon: Icons.label_outline,
    title: knobs.string(label: '제목', initialValue: '아직 태그가 없습니다'),
    message: knobs.stringOrNull(
      label: '설명',
      initialValue: '태그 그룹을 만들어 태그를 정리해보세요',
    ),
    actionLabel: knobs.stringOrNull(label: '버튼', initialValue: '첫 태그 그룹 만들기'),
    onAction: () {},
  );
}
