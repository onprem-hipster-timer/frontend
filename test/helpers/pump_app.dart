import 'package:momeet/core/providers/retry_policy.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// ProviderScope + MaterialApp으로 감싼 위젯 트리를 생성하는 헬퍼.
///
/// ```dart
/// await tester.pumpWidget(
///   pumpApp(const MyWidget(), overrides: [myProvider.overrideWithValue(mock)]),
/// );
/// ```
Widget pumpApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    retry: appRetry,
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}
