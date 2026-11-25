import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '화면 위 안내 카드', type: AppHintCard, path: '[공통]/상태 안내')
Widget appHintCard(BuildContext context) {
  final knobs = context.knobs;
  final title = knobs.stringOrNull(
    label: '제목',
    description: '비우면 안내 문장만 둔다(할 일 목록 화면)',
    initialValue: '해야 할 일 목록 관리',
  );
  final message = knobs.string(
    label: '안내 문장',
    initialValue: '해야 할 일 목록을 선택해서 할 일들을 관리하세요.',
  );
  final icon = knobs.object.dropdown(
    label: '아이콘',
    options: const [Icons.dashboard_rounded, Icons.info_outline],
    labelBuilder: (icon) => icon == Icons.info_outline ? '안내' : '대시보드',
  );
  // 앱에서는 목록 화면 맨 위에 여백 16을 두고 놓인다
  return Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: AppHintCard(title: title, message: message, icon: icon),
    ),
  );
}
