import 'package:flutter/material.dart';
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
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}
