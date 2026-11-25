import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/todo.dart' show TodoStatusSelectorView;
import 'package:momeet/features/trial/presentation/widgets/trial_inert.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '보이기만 하는 컨트롤', type: TrialInert, path: '[체험하기]')
Widget trialInert(BuildContext context) {
  // 할 일의 상태 아이콘. 앱과 같은 모양이지만 눌러도, Tab으로 옮겨 와 Enter를 눌러도 메뉴가 열리지 않는다
  return Center(
    child: TrialInert(
      child: TodoStatusSelectorView(
        status: TodoStatus.scheduled,
        onSelected: (_) {},
      ),
    ),
  );
}
