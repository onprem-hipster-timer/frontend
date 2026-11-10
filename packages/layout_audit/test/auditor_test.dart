import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

import 'support.dart';

void main() {
  testWidgets('Stack에서 겹친 두 Text를 겹침으로 찾고 위쪽 Text와 가리는 위젯을 이름 붙인다', (
    tester,
  ) async {
    await pumpInApp(
      tester,
      Stack(children: [
        at(10, 10, squareText('AAAA')),
        at(20, 15, squareText('BBBB'))
      ]),
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
    await pumpInApp(
      tester,
      Stack(
        children: [
          at(0, 0, SizedBox(width: 100, child: squareText('AAAAA BB'))),
          at(60, 22, squareText('C')),
        ],
      ),
    );

    expect(tester.getSize(find.text('AAAAA BB')).height, 40);
    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('가운데 정렬된 짧은 텍스트의 양쪽 빈 공간은 겹침이 아니다', (tester) async {
    await pumpInApp(
      tester,
      Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 200,
            child: Text('AB', style: squareStyle, textAlign: TextAlign.center),
          ),
          at(0, 0, squareText('C')),
          at(170, 0, squareText('D')),
        ],
      ),
    );

    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('Stack 밖에서 밀려 나온 Text도 겹침으로 찾는다', (tester) async {
    await pumpInApp(
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
                child: squareText('AAAAAAAA'),
              ),
            ),
            squareText('B'),
          ],
        ),
      ),
    );

    final overlaps = ofKind(auditLayout(tester), LayoutFindingKind.overlap);

    expect(overlaps, hasLength(1));
    expect(overlaps.single.insideStack, isFalse);
    expect(overlaps.single.texts.toSet(), {'AAAAAAAA', 'B'});
  });

  testWidgets('25% 미만 살짝 겹치면 notice, 완전히 덮이면 warning이다', (tester) async {
    await pumpInApp(
      tester,
      Stack(children: [
        at(0, 0, squareText('AAAA')),
        at(75, 0, squareText('BBBB'))
      ]),
    );
    final slight = auditLayout(tester).single;
    expect(slight.severity, LayoutSeverity.notice);
    expect(slight.coveredFraction, closeTo(5 / 80, 0.001));

    await pumpInApp(
      tester,
      Stack(
          children: [at(0, 0, squareText('AAAA')), at(20, 0, squareText('B'))]),
    );
    final covered = auditLayout(tester).single;
    expect(covered.severity, LayoutSeverity.warning);
    expect(covered.coveredFraction, 1.0);
  });

  testWidgets('2px 이하 겹침은 보고하지 않는다', (tester) async {
    await pumpInApp(
      tester,
      Stack(
        children: [
          at(0, 0, squareText('AAAA')),
          at(78, 0, squareText('BBBB')),
          at(0, 39, squareText('CCCC')),
          at(0, 58, squareText('DDDD')),
        ],
      ),
    );

    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('Expanded + ellipsis는 겹침이 아니라 말줄임이다', (tester) async {
    await pumpInApp(
      tester,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '아주 긴 제목이 들어가서 한 줄에 다 들어가지 않는 경우',
              style: squareStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          squareText('수정'),
        ],
      ),
    );

    final findings = auditLayout(tester);

    expect(ofKind(findings, LayoutFindingKind.overlap), isEmpty);
    final truncation = ofKind(findings, LayoutFindingKind.truncation);
    expect(truncation, hasLength(1));
    expect(truncation.single.severity, LayoutSeverity.notice);
    expect(truncation.single.message, contains('(maxLines 1)'));
    expect(findings, hasLength(1));
  });

  testWidgets('TextOverflow.clip으로 잘려 나간 글자는 잘라냄이다', (tester) async {
    await pumpInApp(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 60,
          child: Text(
            'AAAAAAAA',
            style: squareStyle,
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
    await pumpInApp(
      tester,
      Stack(
          clipBehavior: Clip.none, children: [at(340, 0, squareText('AAAA'))]),
    );

    final findings = auditLayout(tester);

    final offscreen = ofKind(findings, LayoutFindingKind.offscreen);
    expect(offscreen, hasLength(1));
    expect(offscreen.single.severity, LayoutSeverity.warning);
    expect(offscreen.single.message, contains('화면 오른쪽 밖으로 60.0px'));
    expect(findings, hasLength(1));
  });

  testWidgets('나란히 놓인 두 Text는 겹치지 않는다', (tester) async {
    await pumpInApp(
      tester,
      Row(children: [squareText('AAA'), squareText('BBB')]),
    );

    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('Offstage·Opacity(0)·IndexedStack에 가려진 Text는 무시한다',
      (tester) async {
    await pumpInApp(
      tester,
      Stack(
        children: [
          at(0, 0, squareText('AAAA')),
          at(0, 0, Offstage(child: squareText('BBBB'))),
          at(0, 0, Opacity(opacity: 0, child: squareText('CCCC'))),
          at(
            0,
            0,
            IndexedStack(
              index: 0,
              children: [
                const SizedBox(width: 1, height: 1),
                squareText('DDDD')
              ],
            ),
          ),
        ],
      ),
    );

    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('스크롤로 잘린 부분은 겹침·잘라냄·이탈로 보지 않는다', (tester) async {
    await pumpInApp(
      tester,
      ListView(
        controller: ScrollController(initialScrollOffset: 10),
        children: [
          for (var i = 0; i < 30; i++)
            SizedBox(height: 90, child: squareText('Item $i')),
        ],
      ),
    );

    // 첫 항목 글자는 위쪽 10px이 뷰포트에 잘리고, 화면 아래 캐시 영역 항목은 보이지 않는다.
    expect(tester.getRect(find.text('Item 0')).top, -10);
    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('스크롤 영역 바깥 조상의 잘라내기로 잘린 글자도 잘라냄으로 보지 않는다', (tester) async {
    await pumpInApp(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: ClipRect(
          child: SizedBox(
            width: 200,
            height: 50,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < 6; i++) squareText('LINE$i'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final clipped = auditLayout(
      tester,
    ).where((f) => f.kind == LayoutFindingKind.clipped);

    expect(clipped, isEmpty);
  });

  testWidgets('WidgetSpan 안의 Text는 바깥 Text와 겹침으로 보지 않는다', (tester) async {
    await pumpInApp(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: Text.rich(
          TextSpan(
            style: squareStyle,
            children: [
              const TextSpan(text: 'AA'),
              WidgetSpan(child: squareText('BB')),
              const TextSpan(text: 'CC'),
            ],
          ),
        ),
      ),
    );

    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('칸별로 그리는 ListTile 안의 겹침은 순서 불명으로 보고한다', (tester) async {
    await pumpInApp(
      tester,
      ListTile(
        title: SizedBox(
          width: 20,
          height: 20,
          child: OverflowBox(
            maxWidth: 400,
            alignment: Alignment.centerLeft,
            child: squareText('A' * 16),
          ),
        ),
        trailing: squareText('BB'),
      ),
    );

    final overlap =
        ofKind(auditLayout(tester), LayoutFindingKind.overlap).single;

    expect(overlap.zOrderKnown, isFalse);
    expect(overlap.coveringRoot, isNull);
    expect(overlap.message, contains('겹칩니다 (순서 불명)'));
  });

  testWidgets('떠 있는 버튼이 목록 글자를 덮는 것은 겹침으로 보지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              for (var i = 0; i < 40; i++)
                Text('항목 $i ' * 20, maxLines: 1, softWrap: false),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {},
            label: const Text('새 항목 만들기'),
          ),
        ),
      ),
    );

    final findings = auditLayout(tester)
        .where((f) => f.kind == LayoutFindingKind.overlap)
        .toList();

    expect(findings, isEmpty);
  });

  testWidgets('within 밖의 겹침은 보고하지 않는다', (tester) async {
    const inside = Key('inside');
    await pumpInApp(
      tester,
      Column(
        children: [
          SizedBox(key: inside, height: 30, child: squareText('AAAA')),
          const OverlappingPair(),
        ],
      ),
    );

    expect(auditLayout(tester), hasLength(1));
    expect(auditLayout(tester, within: find.byKey(inside)), isEmpty);
    expect(
      auditLayout(tester, within: find.byType(OverlappingPair)),
      hasLength(1),
    );
  });

  testWidgets('ignore로 의도한 겹침을 뺄 수 있다', (tester) async {
    await pumpInApp(tester, const OverlappingPair());

    final findings = auditLayout(
      tester,
      options: LayoutAuditOptions(ignore: (f) => f.texts.contains('BBBB')),
    );

    expect(findings, isEmpty);
  });

  testWidgets('같은 위젯 쌍의 반복 겹침은 하나로 묶고 횟수를 센다', (tester) async {
    await pumpInApp(
      tester,
      Column(
        children: [for (var i = 0; i < 5; i++) const OverlappingPair()],
      ),
    );

    final findings = auditLayout(tester);

    expect(findings, hasLength(1));
    expect(findings.single.count, 5);
    expect(findings.single.toString(), endsWith('(x5)'));
  });

  testWidgets('찾은 위치가 이 테스트 파일의 줄을 가리킨다', (tester) async {
    // 공용 헬퍼가 아니라 이 파일에서 위젯을 만들어야 위치가 이 파일을 가리킨다.
    await pumpInApp(
      tester,
      const Stack(
        children: [
          Positioned(left: 0, top: 0, child: Text('AAAA', style: squareStyle)),
          Positioned(left: 10, top: 0, child: Text('BBBB', style: squareStyle)),
        ],
      ),
    );

    final overlap = auditLayout(tester).single;

    expect(overlap.locations, hasLength(2));
    for (final location in [...overlap.locations, overlap.coveringRoot]) {
      expect('$location', matches(RegExp(r'^test/auditor_test\.dart:\d+$')));
    }
    expect(overlap.locations[0], isNot(overlap.locations[1]));
  });

  testWidgets('프레임 사이에 움직인 텍스트는 이동으로 알리고 그 겹침은 info로 낮춘다', (tester) async {
    Widget scene(double left) => Stack(
          children: [
            at(0, 0, squareText('AAAA')),
            at(left, 0, squareText('BBBB'))
          ],
        );
    await pumpInApp(tester, scene(44));
    final previous = snapshotLeafBoxes(tester);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: scene(20))));

    final findings = auditLayout(tester, previousFrame: previous);

    final moving = ofKind(findings, LayoutFindingKind.moving);
    expect(moving, hasLength(1));
    expect(moving.single.texts, ['BBBB']);
    expect(moving.single.message, contains('24.0px 이동했습니다'));
    expect(
      ofKind(findings, LayoutFindingKind.overlap).single.severity,
      LayoutSeverity.info,
    );

    final settled = auditLayout(
      tester,
      previousFrame: snapshotLeafBoxes(tester),
    );
    expect(ofKind(settled, LayoutFindingKind.moving), isEmpty);
    expect(settled.single.severity, LayoutSeverity.warning);
  });

  testWidgets('maxLeaves를 넘으면 검사를 건너뛰고 info 하나만 돌려준다', (tester) async {
    await pumpInApp(tester, const OverlappingPair());

    final findings = auditLayout(
      tester,
      options: const LayoutAuditOptions(maxLeaves: 1),
    );

    expect(findings, hasLength(1));
    expect(findings.single.severity, LayoutSeverity.info);
    expect(findings.single.message, startsWith('[점검 건너뜀] '));
  });

  testWidgets('SingleChildScrollView로 잘린 부분도 잘라냄·이탈로 보지 않는다', (tester) async {
    await pumpInApp(
      tester,
      SingleChildScrollView(
        controller: ScrollController(initialScrollOffset: 10),
        child: Column(
          children: [
            for (var i = 0; i < 30; i++)
              SizedBox(height: 90, child: squareText('Item $i')),
          ],
        ),
      ),
    );

    expect(tester.getRect(find.text('Item 0')).top, -10);
    expect(auditLayout(tester), isEmpty);
  });

  test('점검 실패·건너뜀 발견은 info이고 같은 접두어를 쓴다', () {
    final failed = LayoutFinding.auditFailed(StateError('x'));
    expect(failed.severity, LayoutSeverity.info);
    expect(failed.message, startsWith('[점검 실패] '));
    expect(failed.message, contains('x'));

    final skipped = LayoutFinding.auditSkipped(leaves: 2001, maxLeaves: 2000);
    expect(skipped.severity, LayoutSeverity.info);
    expect(skipped.message, contains('2001개'));
    expect(skipped.message, contains('maxLeaves(2000)'));
  });

  testWidgets('화면 밖으로 완전히 나간 텍스트도 이탈이다', (tester) async {
    await pumpInApp(
      tester,
      Stack(
          clipBehavior: Clip.none, children: [at(400, 0, squareText('AAAA'))]),
    );

    final offscreen = ofKind(auditLayout(tester), LayoutFindingKind.offscreen);
    expect(offscreen, hasLength(1));
    expect(offscreen.single.message, contains('화면 오른쪽 밖으로 120.0px'));
  });

  testWidgets('같은 줄 단어 사이 빈칸에 놓인 이웃은 겹침이 아니다', (tester) async {
    await pumpInApp(
      tester,
      Stack(
        children: [
          at(0, 0, squareText('AAAA      BBBB')),
          at(120, 0, squareText('C')),
        ],
      ),
    );

    expect(auditLayout(tester), isEmpty);
  });

  testWidgets('앞에 그려진 글자가 IgnorePointer여도 그리는 순서로 위를 판단한다', (tester) async {
    await pumpInApp(
      tester,
      Stack(
        children: [
          at(10, 10, squareText('AAAA')),
          at(20, 15, IgnorePointer(child: squareText('BBBB'))),
        ],
      ),
    );

    final overlap = auditLayout(tester).single;
    expect(overlap.zOrderKnown, isTrue);
    expect(overlap.texts, ['BBBB', 'AAAA']);
  });

  testWidgets('순서를 모르는 겹침은 왼쪽 위치와 상관없이 같은 쌍을 한 묶음으로 센다', (tester) async {
    // 첫 타일은 제목이 오른쪽으로, 둘째 타일은 trailing이 왼쪽으로 넘쳐 왼쪽에 오는 글자가 바뀐다.
    // 두 글자의 생성 위치가 달라야 하므로 공용 헬퍼 대신 여기서 만든다.
    Widget tile(String title, String trailing) => ListTile(
          title: SizedBox(
            width: 20,
            height: 20,
            child: OverflowBox(
              maxWidth: 400,
              alignment: Alignment.centerLeft,
              child: Text(title, style: squareStyle),
            ),
          ),
          trailing: SizedBox(
            width: 20,
            height: 20,
            child: OverflowBox(
              maxWidth: 400,
              alignment: Alignment.centerRight,
              child: Text(trailing, style: squareStyle),
            ),
          ),
        );
    await pumpInApp(
      tester,
      Column(children: [tile('A' * 16, 'B'), tile('A', 'B' * 17)]),
    );

    final overlap =
        ofKind(auditLayout(tester), LayoutFindingKind.overlap).single;
    expect(overlap.count, 2);
  });
}
