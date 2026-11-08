import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

// 테마의 줄 높이·자간을 지워 테스트 글꼴의 글자가 20px 정사각형이 되게 한다.
const _style = TextStyle(fontSize: 20, height: 1, letterSpacing: 0);

Future<void> _pump(WidgetTester tester, Widget body) async {
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: body)));
}

Widget _at(double left, double top, Widget child) =>
    Positioned(left: left, top: top, child: child);

Widget _text(String text) => Text(text, style: _style);

List<LayoutFinding> _ofKind(
  List<LayoutFinding> findings,
  LayoutFindingKind kind,
) =>
    findings.where((f) => f.kind == kind).toList();

class _OverlappingPair extends StatelessWidget {
  const _OverlappingPair();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Stack(
        children: [
          _at(0, 0, const Text('AAAA', style: _style)),
          _at(10, 0, const Text('BBBB', style: _style)),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('Stack에서 겹친 두 Text를 겹침으로 찾고 위쪽 Text와 가리는 위젯을 이름 붙인다', (
    tester,
  ) async {
    await _pump(
      tester,
      Stack(children: [_at(10, 10, _text('AAAA')), _at(20, 15, _text('BBBB'))]),
    );

    final findings = auditLayout(tester);

    expect(findings, hasLength(1));
    final overlap = findings.single;
    expect(overlap.kind, LayoutFindingKind.overlap);
    expect(overlap.severity, LayoutSeverity.warning);
    expect(overlap.insideStack, isTrue);
    expect(overlap.zOrderKnown, isTrue);
    expect(overlap.texts, ['BBBB', 'AAAA']);
    expect(overlap.coveringRoot, isNotNull);
    expect(overlap.rects.last, const Rect.fromLTRB(20, 15, 90, 30));
    expect(overlap.message, contains('Stack 안'));
    expect(overlap.message, contains('∩=(20.0,15.0,90.0,30.0)'));
  });

  testWidgets('두 줄 텍스트의 짧은 둘째 줄 옆 빈 공간에 놓인 이웃은 겹침이 아니다', (tester) async {
    await _pump(
      tester,
      Stack(
        children: [
          _at(0, 0, SizedBox(width: 100, child: _text('AAAAA BB'))),
          _at(60, 22, _text('C')),
        ],
      ),
    );

    expect(tester.getSize(find.text('AAAAA BB')).height, 40);
    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('가운데 정렬된 짧은 텍스트의 양쪽 빈 공간은 겹침이 아니다', (tester) async {
    await _pump(
      tester,
      Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 200,
            child: Text('AB', style: _style, textAlign: TextAlign.center),
          ),
          _at(0, 0, _text('C')),
          _at(170, 0, _text('D')),
        ],
      ),
    );

    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('Stack 밖에서 밀려 나온 Text도 겹침으로 찾는다', (tester) async {
    await _pump(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 20,
              child: OverflowBox(
                maxWidth: 300,
                alignment: Alignment.centerLeft,
                child: _text('AAAAAAAA'),
              ),
            ),
            _text('B'),
          ],
        ),
      ),
    );

    final overlaps = _ofKind(auditLayout(tester), LayoutFindingKind.overlap);

    expect(overlaps, hasLength(1));
    expect(overlaps.single.insideStack, isFalse);
    expect(overlaps.single.texts.toSet(), {'AAAAAAAA', 'B'});
  });

  testWidgets('25% 미만 살짝 겹치면 notice, 완전히 덮이면 warning이다', (tester) async {
    await _pump(
      tester,
      Stack(children: [_at(0, 0, _text('AAAA')), _at(75, 0, _text('BBBB'))]),
    );
    final slight = auditLayout(tester).single;
    expect(slight.severity, LayoutSeverity.notice);
    expect(slight.coveredFraction, closeTo(5 / 80, 0.001));

    await _pump(
      tester,
      Stack(children: [_at(0, 0, _text('AAAA')), _at(20, 0, _text('B'))]),
    );
    final covered = auditLayout(tester).single;
    expect(covered.severity, LayoutSeverity.warning);
    expect(covered.coveredFraction, 1.0);
  });

  testWidgets('2px 이하 겹침은 보고하지 않는다', (tester) async {
    await _pump(
      tester,
      Stack(
        children: [
          _at(0, 0, _text('AAAA')),
          _at(78, 0, _text('BBBB')),
          _at(0, 39, _text('CCCC')),
          _at(0, 58, _text('DDDD')),
        ],
      ),
    );

    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('Expanded + ellipsis는 겹침이 아니라 말줄임이다', (tester) async {
    await _pump(
      tester,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '아주 긴 제목이 들어가서 한 줄에 다 들어가지 않는 경우',
              style: _style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _text('수정'),
        ],
      ),
    );

    final findings = auditLayout(tester);

    expect(_ofKind(findings, LayoutFindingKind.overlap), isEmpty);
    final truncation = _ofKind(findings, LayoutFindingKind.truncation);
    expect(truncation, hasLength(1));
    expect(truncation.single.severity, LayoutSeverity.notice);
    expect(truncation.single.message, contains('(maxLines 1)'));
    expect(findings, hasLength(1));
  });

  testWidgets('TextOverflow.clip으로 잘려 나간 글자는 잘라냄이다', (tester) async {
    await _pump(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 60,
          child: Text(
            'AAAAAAAA',
            style: _style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
          ),
        ),
      ),
    );

    final findings = auditLayout(tester);

    expect(findings, hasLength(1));
    expect(findings.single.kind, LayoutFindingKind.clipped);
    expect(findings.single.severity, LayoutSeverity.warning);
    expect(findings.single.message, contains('100.0px 잘려 나갑니다'));
  });

  testWidgets('클립 없는 Positioned 텍스트가 화면 밖으로 나가면 이탈이다', (tester) async {
    await _pump(
      tester,
      Stack(clipBehavior: Clip.none, children: [_at(340, 0, _text('AAAA'))]),
    );

    final findings = auditLayout(tester);

    final offscreen = _ofKind(findings, LayoutFindingKind.offscreen);
    expect(offscreen, hasLength(1));
    expect(offscreen.single.severity, LayoutSeverity.warning);
    expect(offscreen.single.message, contains('화면 오른쪽 밖으로 60.0px'));
    expect(findings, hasLength(1));
  });

  testWidgets('나란히 놓인 두 Text는 겹치지 않는다', (tester) async {
    await _pump(
      tester,
      Row(children: [_text('AAA'), _text('BBB')]),
    );

    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('Offstage·Opacity(0)·IndexedStack에 가려진 Text는 무시한다',
      (tester) async {
    await _pump(
      tester,
      Stack(
        children: [
          _at(0, 0, _text('AAAA')),
          _at(0, 0, Offstage(child: _text('BBBB'))),
          _at(0, 0, Opacity(opacity: 0, child: _text('CCCC'))),
          _at(
            0,
            0,
            IndexedStack(
              index: 0,
              children: [const SizedBox(width: 1, height: 1), _text('DDDD')],
            ),
          ),
        ],
      ),
    );

    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('스크롤로 잘린 부분은 겹침·잘라냄·이탈로 보지 않는다', (tester) async {
    await _pump(
      tester,
      ListView(
        controller: ScrollController(initialScrollOffset: 10),
        children: [
          for (var i = 0; i < 30; i++)
            SizedBox(height: 90, child: _text('Item $i')),
        ],
      ),
    );

    // 첫 항목 글자는 위쪽 10px이 뷰포트에 잘리고, 화면 아래 캐시 영역 항목은 보이지 않는다.
    expect(tester.getRect(find.text('Item 0')).top, -10);
    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('WidgetSpan 안의 Text는 바깥 Text와 겹침으로 보지 않는다', (tester) async {
    await _pump(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: Text.rich(
          TextSpan(
            style: _style,
            children: [
              const TextSpan(text: 'AA'),
              WidgetSpan(child: _text('BB')),
              const TextSpan(text: 'CC'),
            ],
          ),
        ),
      ),
    );

    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('IgnorePointer 아래 겹침은 순서 불명으로 보고한다', (tester) async {
    await _pump(
      tester,
      IgnorePointer(
        child: Stack(
          children: [_at(10, 10, _text('AAAA')), _at(20, 15, _text('BBBB'))],
        ),
      ),
    );

    final overlap = auditLayout(tester).single;

    expect(overlap.zOrderKnown, isFalse);
    expect(overlap.coveringRoot, isNull);
    expect(overlap.message, contains('70.0x15.0 겹칩니다 (순서 불명)'));
  });

  testWidgets('within 밖의 겹침은 보고하지 않는다', (tester) async {
    const inside = Key('inside');
    await _pump(
      tester,
      Column(
        children: [
          SizedBox(key: inside, height: 30, child: _text('AAAA')),
          const _OverlappingPair(),
        ],
      ),
    );

    expect(auditLayout(tester), hasLength(1));
    expect(auditLayout(tester, within: find.byKey(inside)), isEmpty);
    expect(
      auditLayout(tester, within: find.byType(_OverlappingPair)),
      hasLength(1),
    );
  });

  testWidgets('ignore로 의도한 겹침을 뺄 수 있다', (tester) async {
    await _pump(tester, const _OverlappingPair());

    final findings = auditLayout(
      tester,
      options: LayoutAuditOptions(ignore: (f) => f.texts.contains('BBBB')),
    );

    expect(findings, isEmpty);
  });

  testWidgets('같은 위젯 쌍의 반복 겹침은 하나로 묶고 횟수를 센다', (tester) async {
    await _pump(
      tester,
      Column(
        children: [for (var i = 0; i < 5; i++) const _OverlappingPair()],
      ),
    );

    final findings = auditLayout(tester);

    expect(findings, hasLength(1));
    expect(findings.single.count, 5);
    expect(findings.single.toString(), endsWith('(x5)'));
  });

  testWidgets('찾은 위치가 이 테스트 파일의 줄을 가리킨다', (tester) async {
    await _pump(tester, const _OverlappingPair());

    final overlap = auditLayout(tester).single;

    expect(overlap.locations, hasLength(2));
    for (final location in [...overlap.locations, overlap.coveringRoot]) {
      expect('$location', matches(RegExp(r'^test/auditor_test\.dart:\d+$')));
    }
    expect(overlap.locations[0], isNot(overlap.locations[1]));
  });

  testWidgets('프레임 사이에 움직인 텍스트는 이동으로 알리고 그 겹침은 info로 낮춘다', (tester) async {
    Widget scene(double left) => Stack(
          children: [_at(0, 0, _text('AAAA')), _at(left, 0, _text('BBBB'))],
        );
    await _pump(tester, scene(44));
    final previous = snapshotLeafBoxes(tester);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: scene(20))));

    final findings = auditLayout(tester, previousFrame: previous);

    final moving = _ofKind(findings, LayoutFindingKind.moving);
    expect(moving, hasLength(1));
    expect(moving.single.texts, ['BBBB']);
    expect(moving.single.message, contains('24.0px 이동했습니다'));
    expect(
      _ofKind(findings, LayoutFindingKind.overlap).single.severity,
      LayoutSeverity.info,
    );

    final settled = auditLayout(
      tester,
      previousFrame: snapshotLeafBoxes(tester),
    );
    expect(_ofKind(settled, LayoutFindingKind.moving), isEmpty);
    expect(settled.single.severity, LayoutSeverity.warning);
  });

  testWidgets('maxLeaves를 넘으면 검사를 건너뛰고 info 하나만 돌려준다', (tester) async {
    await _pump(tester, const _OverlappingPair());

    final findings = auditLayout(
      tester,
      options: const LayoutAuditOptions(maxLeaves: 1),
    );

    expect(findings, hasLength(1));
    expect(findings.single.severity, LayoutSeverity.info);
  });

  testWidgets('SingleChildScrollView로 잘린 부분도 잘라냄·이탈로 보지 않는다', (tester) async {
    await _pump(
      tester,
      SingleChildScrollView(
        controller: ScrollController(initialScrollOffset: 10),
        child: Column(
          children: [
            for (var i = 0; i < 30; i++)
              SizedBox(height: 90, child: _text('Item $i')),
          ],
        ),
      ),
    );

    expect(tester.getRect(find.text('Item 0')).top, -10);
    expect(auditLayout(tester), isEmpty);
  });
}
