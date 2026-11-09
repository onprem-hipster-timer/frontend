import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

import 'support.dart';

void main() {
  testWidgets('이미지 위에 올라간 글자는 겹침이다', (tester) async {
    await pumpInApp(
      tester,
      Stack(children: [
        at(0, 0, const RawImage(width: 80, height: 40)),
        at(10, 10, squareText('AAAA')),
      ]),
    );
    final f = auditLayout(tester);
    expect(ofKind(f, LayoutFindingKind.overlap), hasLength(1));
    expect(f.single.texts, contains('AAAA'));
  });

  testWidgets('아이콘 위 글자는 겹침이고 빈 문자열은 리프가 아니다', (tester) async {
    await pumpInApp(
      tester,
      Stack(children: [
        at(0, 0, const Icon(Icons.star, size: 40)),
        at(5, 5, squareText('AA')),
        at(200, 200, squareText('')),
        at(200, 200, squareText('ZZ')),
      ]),
    );
    final f = auditLayout(tester);
    expect(ofKind(f, LayoutFindingKind.overlap), hasLength(1));
    expect(f.single.texts, contains('AA'));
  });

  testWidgets('겹침 폭이 정확히 2px이면 보고하지 않고 2.5px이면 보고한다', (tester) async {
    await pumpInApp(
        tester,
        Stack(children: [
          at(0, 0, squareText('AAAA')),
          at(78, 0, squareText('BBBB'))
        ]));
    expect(auditLayout(tester), isEmpty);
    await pumpInApp(
        tester,
        Stack(children: [
          at(0, 0, squareText('AAAA')),
          at(77.5, 0, squareText('BBBB'))
        ]));
    expect(
        ofKind(auditLayout(tester), LayoutFindingKind.overlap), hasLength(1));
  });

  testWidgets('RenderFlex가 넘친 트리에서도 예외 없이 검사한다', (tester) async {
    await pumpInApp(
      tester,
      Row(children: [squareText('A' * 30), squareText('B' * 10)]),
    );
    expect(tester.takeException(), isNotNull);
    final f = auditLayout(tester);
    expect(f, isNotEmpty);
    expect(f.any((e) => e.message.contains('점검 실패')), isFalse);
  });

  testWidgets('다이얼로그가 뒤 화면 글자를 덮는 것은 겹침이 아니다', (tester) async {
    await pumpInApp(
      tester,
      Builder(
        builder: (context) => Column(children: [
          for (var i = 0; i < 30; i++) squareText('뒤 화면 글자 $i'),
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                  title: squareText('제목'), content: squareText('내용')),
            ),
            child: const Text('열기'),
          ),
        ]),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    final f = auditLayout(tester);
    expect(ofKind(f, LayoutFindingKind.overlap), isEmpty);
  });

  testWidgets('within이 여러 요소에 매치돼도 발견을 중복 보고하지 않는다', (tester) async {
    await pumpInApp(
        tester,
        Column(
            children: [for (var i = 0; i < 5; i++) const OverlappingPair()]));
    final f = auditLayout(tester, within: find.byType(OverlappingPair));
    expect(f, hasLength(1));
    expect(f.single.count, 5);
  });

  testWidgets('글자 배율 2.0에서 고정 폭 상자에 갇힌 글자는 잘라냄이다', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpInApp(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
            width: 100,
            child:
                Text('AAAA', style: squareStyle, maxLines: 1, softWrap: false)),
      ),
    );
    final f = auditLayout(tester);
    expect(ofKind(f, LayoutFindingKind.clipped), hasLength(1));
    expect(f.single.message, contains('60.0px'));
  });

  testWidgets('클립 경계를 2px 넘긴 글자만 잘라냄이다', (tester) async {
    Widget clipped(double width) => Align(
          alignment: Alignment.topLeft,
          child: ClipRect(
            child: SizedBox(
              width: width,
              height: 20,
              child: OverflowBox(
                  maxWidth: 300,
                  alignment: Alignment.centerLeft,
                  child: squareText('AAAA')),
            ),
          ),
        );
    await pumpInApp(tester, clipped(78));
    expect(auditLayout(tester), isEmpty);
    await pumpInApp(tester, clipped(77));
    expect(
        ofKind(auditLayout(tester), LayoutFindingKind.clipped), hasLength(1));
  });
}
