import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/widgets/app_scaffold.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '기본 화면 틀', type: AppScaffold, path: '[공통]/화면 틀')
Widget appScaffold(BuildContext context) {
  final knobs = context.knobs;
  final title = knobs.string(label: '화면 제목', initialValue: '홈');
  final appBar = knobs.boolean(label: '앱바', initialValue: true);
  final fab = knobs.boolean(label: '추가 버튼', description: '화면 오른쪽 아래에 떠 있는 버튼');
  return AppScaffold(
    title: title,
    showAppBar: appBar,
    floatingActionButton: fab
        ? FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add))
        : null,
    body: AppEmptyState(
      icon: Icons.event_note_outlined,
      title: '오늘은 일정이 없습니다',
      message: '새 일정을 추가해 하루를 계획해보세요',
      actionLabel: '일정 추가',
      onAction: () {},
    ),
  );
}
