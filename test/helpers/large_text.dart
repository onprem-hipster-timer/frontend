import 'dart:ui' show Size;

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

/// 화면을 가장 좁은 폰(320×568)으로, 글자를 2배로 바꾸고 다시 그린다. 띄운 뒤에 부른다.
Future<void> useLargeTextOnSmallPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpAndSettle();
}

/// [text]가 말줄임이나 줄 수 제한으로 잘리지 않았다.
void expectWholeText(WidgetTester tester, Finder text) => expect(
  tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
  isFalse,
  reason: '$text가 잘렸습니다',
);
