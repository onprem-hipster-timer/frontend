import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

import 'support.dart';

/// [build]를 글자 1.0배와 [to]배로 차례로 점검하고 배율 비교 보고서의 발견을 돌려준다.
Future<List<LayoutFinding>> compareScales(
  WidgetTester tester,
  String name,
  Widget Function() build, {
  ScaleAuditOptions scale = const ScaleAuditOptions(),
  double to = 2.0,
  TestViewport scaledViewport = TestViewports.phoneSmall,
  bool strict = false,
  bool scaleStrict = false,
  List<LayoutReport>? main,
}) async {
  final reports = <LayoutReport>[];
  final sink = LayoutReportSink(
    reportDir: tempDir().path,
    environment: const {},
    writeLine: (_) {},
    onReport: reports.add,
  );
  for (final auditCase in [
    const LayoutAuditCase(TestViewports.phoneSmall, 1.0),
    LayoutAuditCase(scaledViewport, to),
  ]) {
    await tester.pumpAndAuditLayout(
      name: name,
      auditCase: auditCase,
      child: build(),
      sink: sink,
      scale: scale,
      strict: strict,
      scaleStrict: scaleStrict,
    );
  }
  main?.addAll(reports.where((r) => r.name == name));
  return [
    for (final report in reports)
      if (report.name == scaleReportName(name)) ...report.findings,
  ];
}

const _date = Text(
  '2026년 11월',
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: squareStyle,
);

/// 글자 배율이 1.5배를 넘으면 [large], 아니면 [normal]을 그린다.
class _ByScale extends StatelessWidget {
  const _ByScale({required this.normal, required this.large});

  final Widget normal;
  final Widget large;

  @override
  Widget build(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) > 1.5 ? large : normal;
}

/// 글자 배율에 비례해 높아지는 빈칸 아래에 '저장' 버튼을 둔다.
class _PushedButton extends StatelessWidget {
  const _PushedButton();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: MediaQuery.textScalerOf(context).scale(500)),
          FilledButton(onPressed: () {}, child: const Text('저장')),
        ],
      );
}

/// 제목은 배율대로 커지고 값은 좁은 칸에 맞춰 줄어드는 카드.
Widget _tile() => const Row(
      children: [
        Text('제목', style: TextStyle(fontSize: 14, height: 1)),
        Spacer(),
        SizedBox(
          width: 40,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('42', style: TextStyle(fontSize: 18, height: 1)),
          ),
        ),
      ],
    );

void main() {
  group('배율 때문에 생긴 말줄임', () {
    testWidgets('1.0배에서 다 보이던 글자가 2.0배에서 말줄임되면 경고한다', (tester) async {
      final found = await compareScales(
        tester,
        'truncate',
        () => const SizedBox(width: 200, child: _date),
      );

      expect(ofKind(found, LayoutFindingKind.scaleTruncation), [
        isA<LayoutFinding>()
            .having((f) => f.severity, 'severity', LayoutSeverity.warning)
            .having((f) => f.texts, 'texts', ['2026년 11월']),
      ]);
    });

    testWidgets('1.0배에서도 이미 잘린 글자는 배율 탓이 아니다', (tester) async {
      final found = await compareScales(
        tester,
        'truncate-already',
        () => const SizedBox(width: 100, child: _date),
      );

      expect(ofKind(found, LayoutFindingKind.scaleTruncation), isEmpty);
    });

    testWidgets('사용자가 넣는 글자를 품은 문단은 보지 않는다', (tester) async {
      final found = await compareScales(
        tester,
        'truncate-user',
        () => const SizedBox(width: 200, child: _date),
        scale: const ScaleAuditOptions(userTexts: ['11월']),
      );

      expect(ofKind(found, LayoutFindingKind.scaleTruncation), isEmpty);
    });

    testWidgets('상자 밖으로 잘려 나가도 말줄임과 같이 본다', (tester) async {
      final found = await compareScales(
        tester,
        'truncate-clip',
        () => const SizedBox(
          width: 200,
          child: Text(
            '2026년 11월',
            softWrap: false,
            overflow: TextOverflow.clip,
            style: squareStyle,
          ),
        ),
      );

      expect(ofKind(found, LayoutFindingKind.scaleTruncation), hasLength(1));
    });
  });

  group('배율 때문에 사라진 글자', () {
    testWidgets('1.0배에 보이던 글자가 2.0배에 없으면 경고한다', (tester) async {
      final found = await compareScales(
        tester,
        'vanish',
        () => const Column(
          children: [
            _ByScale(
              normal: Text('팀 회의', style: squareStyle),
              large: SizedBox(),
            ),
            Text('아래 줄', style: squareStyle),
          ],
        ),
      );

      expect(ofKind(found, LayoutFindingKind.scaleVanished), [
        isA<LayoutFinding>()
            .having((f) => f.severity, 'severity', LayoutSeverity.warning)
            .having((f) => f.texts, 'texts', ['팀 회의']),
      ]);
    });

    testWidgets('같은 자리에서 글자만 바뀐 것은 사라진 것이 아니다', (tester) async {
      final found = await compareScales(
        tester,
        'vanish-adapted',
        () => _ByScale(
          normal: const Text('월요일', style: squareStyle),
          large: const Text('월', style: squareStyle),
        ),
      );

      expect(ofKind(found, LayoutFindingKind.scaleVanished), isEmpty);
    });

    testWidgets('다른 위젯이 같은 글자를 그리면 사라진 것이 아니다', (tester) async {
      final found = await compareScales(
        tester,
        'vanish-redrawn',
        () => const _ByScale(
          normal: Text('팀 회의', style: squareStyle),
          large: Row(children: [Text('팀 회의', style: squareStyle)]),
        ),
      );

      expect(ofKind(found, LayoutFindingKind.scaleVanished), isEmpty);
    });

    testWidgets('목록 끝이 아직 만들어지지 않은 것은 사라진 것이 아니다', (tester) async {
      final found = await compareScales(
        tester,
        'vanish-lazy',
        () => ListView(
          children: [
            for (var i = 0; i < 60; i++) Text('항목 $i', style: squareStyle),
          ],
        ),
      );

      expect(ofKind(found, LayoutFindingKind.scaleVanished), isEmpty);
    });

    testWidgets('목록 안이어도 뒤 항목이 남아 있는데 앞 글자가 없어지면 경고한다', (tester) async {
      final found = await compareScales(
        tester,
        'vanish-in-list',
        () => ListView(
          children: const [
            _ByScale(
              normal: Text('팀 회의', style: squareStyle),
              large: SizedBox(height: 20),
            ),
            Text('아래 줄', style: squareStyle),
          ],
        ),
      );

      expect(
        ofKind(found, LayoutFindingKind.scaleVanished).map((f) => f.texts),
        [
          ['팀 회의'],
        ],
      );
    });
  });

  group('배율 때문에 밀려난 버튼', () {
    testWidgets('스크롤로도 닿을 수 없게 밀려나면 경고한다', (tester) async {
      final found = await compareScales(
        tester,
        'pushed',
        () => const ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            maxHeight: double.infinity,
            child: _PushedButton(),
          ),
        ),
      );

      expect(ofKind(found, LayoutFindingKind.scaleUnreachable), [
        isA<LayoutFinding>()
            .having((f) => f.severity, 'severity', LayoutSeverity.warning)
            .having((f) => f.texts, 'texts', ['저장']),
      ]);
    });

    testWidgets('스크롤로 닿으면 기록만 남긴다', (tester) async {
      final found = await compareScales(
        tester,
        'pushed-scroll',
        () => const SingleChildScrollView(child: _PushedButton()),
      );

      expect(
        ofKind(found, LayoutFindingKind.scaleUnreachable)
            .map((f) => f.severity),
        [LayoutSeverity.notice],
      );
    });

    testWidgets('화면 안에 남아 있으면 보고하지 않는다', (tester) async {
      final found = await compareScales(
        tester,
        'pushed-not',
        () => Center(
          child: FilledButton(onPressed: () {}, child: const Text('저장')),
        ),
      );

      expect(ofKind(found, LayoutFindingKind.scaleUnreachable), isEmpty);
    });
  });

  group('위계 역전', () {
    testWidgets('한 카드 안에서 작던 제목이 값보다 커지면 경고한다', (tester) async {
      final found = await compareScales(
        tester,
        'inversion',
        () => Center(child: SizedBox(width: 200, height: 100, child: _tile())),
      );

      expect(ofKind(found, LayoutFindingKind.scaleInversion), [
        isA<LayoutFinding>()
            .having((f) => f.severity, 'severity', LayoutSeverity.warning)
            .having((f) => f.texts, 'texts', unorderedEquals(['제목', '42'])),
      ]);
    });

    testWidgets('화면 양 끝처럼 멀리 떨어진 두 글자는 비교하지 않는다', (tester) async {
      final found = await compareScales(
        tester,
        'inversion-far',
        () => const Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('제목', style: TextStyle(fontSize: 14, height: 1)),
            SizedBox(
              width: 40,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('42', style: TextStyle(fontSize: 18, height: 1)),
              ),
            ),
          ],
        ),
      );

      expect(ofKind(found, LayoutFindingKind.scaleInversion), isEmpty);
    });

    testWidgets('함께 커지면 순서가 그대로라 보고하지 않는다', (tester) async {
      final found = await compareScales(
        tester,
        'inversion-none',
        () => const Center(
          child: SizedBox(
            width: 300,
            height: 100,
            child: Row(
              children: [
                Text('제목', style: TextStyle(fontSize: 14, height: 1)),
                Spacer(),
                Text('42', style: TextStyle(fontSize: 18, height: 1)),
              ],
            ),
          ),
        ),
      );

      expect(ofKind(found, LayoutFindingKind.scaleInversion), isEmpty);
    });
  });

  group('기존 점검과 따로 동작한다', () {
    testWidgets('배율 비교는 별도 보고서로 내고 기존 보고서에는 섞지 않는다', (tester) async {
      final main = <LayoutReport>[];
      final found = await compareScales(
        tester,
        'separate',
        () => const SizedBox(width: 200, child: _date),
        main: main,
      );

      expect(found, isNotEmpty);
      expect(main, hasLength(2));
      for (final report in main) {
        expect(
          report.findings.map((f) => f.kind),
          everyElement(isNot(isIn(scaleFindingKinds))),
        );
      }
    });

    testWidgets('기존 엄격 모드는 배율 비교 경고로 실패하지 않는다', (tester) async {
      final found = await compareScales(
        tester,
        'strict-main',
        () => const SizedBox(width: 200, child: _date),
        strict: true,
      );

      expect(found, isNotEmpty);
    });

    testWidgets('배율 비교 엄격 모드는 배율 비교 경고로 실패한다', (tester) async {
      Object? error;
      try {
        await compareScales(
          tester,
          'strict-scale',
          () => const SizedBox(width: 200, child: _date),
          scaleStrict: true,
        );
      } on TestFailure catch (e) {
        error = e;
      }

      expect(error, isA<TestFailure>());
    });

    testWidgets('끄면 배율 비교 보고서를 내지 않는다', (tester) async {
      final found = await compareScales(
        tester,
        'disabled',
        () => const SizedBox(width: 200, child: _date),
        scale: const ScaleAuditOptions(enabled: false),
      );

      expect(found, isEmpty);
    });

    testWidgets('화면 크기가 다르면 비교하지 않는다', (tester) async {
      final found = await compareScales(
        tester,
        'other-viewport',
        () => const SizedBox(width: 200, child: _date),
        scaledViewport: TestViewports.phoneLarge,
      );

      expect(found, isEmpty);
    });
  });
}
