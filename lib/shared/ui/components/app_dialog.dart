import 'package:material_ui/material_ui.dart';

/// [builder]가 만든 다이얼로그를 연다. 상태를 들고 있는 다이얼로그에 쓴다.
///
/// 루트 내비게이터 위에 띄워 하단 내비게이션까지 덮는다.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showDialog<T>(context: context, useRootNavigator: true, builder: builder);
