import 'package:material_ui/material_ui.dart';

/// 앱 하단 시트를 연다.
///
/// 루트 내비게이터 위에 띄워 하단 내비게이션까지 덮는다. 손잡이·배경·모서리는
/// 테마를 따르고, 키보드가 올라오면 그만큼 내용을 올린다. 높이는 내용만큼이다.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: builder(context),
  ),
);

/// 끌어서 높이를 바꾸는 긴 목록용 하단 시트를 연다.
///
/// [builder]가 받은 컨트롤러를 목록에 달아야 목록을 끌 때 시트도 함께 움직인다.
Future<T?> showAppScrollableSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext context, ScrollController controller)
  builder,
  double initialSize = 0.6,
  double minSize = 0.25,
  double maxSize = 0.95,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: initialSize,
    minChildSize: minSize,
    maxChildSize: maxSize,
    builder: builder,
  ),
);
