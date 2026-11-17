import 'package:material_ui/material_ui.dart';

/// [context]의 그림 안 [rect]가 화면에 보이게 바깥 굴림 영역들을 굴린다. 애니메이션을 줄였으면 바로 옮긴다
void showAppRect(BuildContext context, Rect rect) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  context.findRenderObject()?.showOnScreen(
    rect: rect,
    duration: reduce ? Duration.zero : const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );
}
