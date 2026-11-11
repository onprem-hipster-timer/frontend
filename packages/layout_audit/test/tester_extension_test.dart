import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

import 'support.dart';

const _case = LayoutAuditCase(TestViewports.iphoneSe1, 1.0);

class _Marquee extends StatefulWidget {
  const _Marquee();

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ClipRect(
        child: SizedBox(
          width: 60,
          height: 20,
          child: OverflowBox(
            maxWidth: 400,
            alignment: Alignment.centerLeft,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(
                offset: Offset(-100 * _controller.value, 0),
                child: child,
              ),
              child: const Text('흘러가는 아주 긴 공지 문구', style: squareStyle),
            ),
          ),
        ),
      ),
    );
  }
}

/// 'BBBB'가 x=40에서 x=10으로 미끄러져 'AAAA' 위에 놓인다.
Widget _slidingIn(Duration duration) => SizedBox(
      height: 30,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 0,
            child: Text('AAAA', style: squareStyle),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 40, end: 10),
              duration: duration,
              builder: (context, dx, child) =>
                  Transform.translate(offset: Offset(dx, 0), child: child),
              child: const Text('BBBB', style: squareStyle),
            ),
          ),
        ],
      ),
    );

void main() {
  late Directory dir;
  late List<String> lines;
  late LayoutReportSink sink;

  setUp(() {
    dir = tempDir();
    lines = [];
    sink = sinkFor(dir, lines: lines);
  });

  testWidgets('조합의 뷰포트와 글자 배율이 적용된다', (tester) async {
    Size? size;
    double? scaled;
    await tester.pumpAndAuditLayout(
      name: 'media',
      auditCase: const LayoutAuditCase(TestViewports.iphoneSe1, 2.0),
      sink: sink,
      child: Builder(
        builder: (context) {
          size = MediaQuery.sizeOf(context);
          scaled = MediaQuery.textScalerOf(context).scale(10);
          return const SizedBox();
        },
      ),
    );

    expect(size, const Size(320, 568));
    expect(scaled, 20);
  });

  testWidgets('겹침이 없으면 빈 보고서를 돌려주고 아무것도 쓰지 않는다', (tester) async {
    final report = await tester.pumpAndAuditLayout(
      name: 'clean',
      auditCase: _case,
      sink: sink,
      child: const Text('안녕하세요', style: squareStyle),
    );

    expect(report.isEmpty, isTrue);
    expect(lines, isEmpty);
    expect(dir.listSync(), isEmpty);
  });

  testWidgets('겹침·넘침·말줄임을 한 보고서에 모아 보고한다', (tester) async {
    final report = await tester.pumpAndAuditLayout(
      name: 'mixed',
      auditCase: _case,
      sink: sink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OverlappingPair(),
          const Row(children: [SizedBox(width: 500, height: 10)]),
          const Row(
            children: [
              Expanded(
                child: Text(
                  '아주 긴 제목이 한 줄에 다 들어가지 않아 말줄임표로 끝납니다',
                  style: squareStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    expect(
      report.findings.map((f) => f.kind).toSet(),
      containsAll([
        LayoutFindingKind.overlap,
        LayoutFindingKind.overflow,
        LayoutFindingKind.truncation,
      ]),
    );
    expect(report.name, 'mixed');
    expect(report.caseLabel, _case.toString());
    expect(lines.single, contains('mixed'));
    expect(report.viewSize, TestViewports.iphoneSe1.logicalSize);
    expect(File('${dir.path}/mixed.md').existsSync(), isTrue);
    expect(File('${dir.path}/mixed.html').existsSync(), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('움직이는 텍스트는 잘림이 아니라 움직임으로 보고한다', (tester) async {
    final report = await tester.pumpAndAuditLayout(
      name: 'marquee',
      auditCase: _case,
      sink: sink,
      child: const _Marquee(),
    );

    expect(ofKind(report.findings, LayoutFindingKind.moving), hasLength(1));
    expect(ofKind(report.findings, LayoutFindingKind.clipped), isEmpty);
    expect(ofKind(report.findings, LayoutFindingKind.truncation), isEmpty);
    expect(ofKind(report.findings, LayoutFindingKind.overlap), isEmpty);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('한 번만 재생되는 입장 애니메이션은 settle 뒤에는 겹침을 원래 심각도로 보고한다', (
    tester,
  ) async {
    final settled = await tester.pumpAndAuditLayout(
      name: 'slide-settled',
      auditCase: _case,
      sink: sink,
      child: _slidingIn(const Duration(milliseconds: 300)),
    );

    expect(ofKind(settled.findings, LayoutFindingKind.moving), isEmpty);
    expect(
      ofKind(settled.findings, LayoutFindingKind.overlap).single.severity,
      LayoutSeverity.warning,
    );
  });

  testWidgets('settle 전이면 아직 움직이는 겹침은 info로 낮춘다', (tester) async {
    final moving = await tester.pumpAndAuditLayout(
      name: 'slide-moving',
      auditCase: _case,
      sink: sink,
      settle: Duration.zero,
      child: _slidingIn(const Duration(seconds: 1)),
    );

    expect(ofKind(moving.findings, LayoutFindingKind.moving), isNotEmpty);
    expect(
      ofKind(moving.findings, LayoutFindingKind.overlap).single.severity,
      LayoutSeverity.info,
    );

    await tester.pumpAndSettle();
  });

  testWidgets('strict이면 warning에서 실패한다', (tester) async {
    await expectLater(
      () => tester.pumpAndAuditLayout(
        name: 'strict',
        auditCase: _case,
        sink: sink,
        strict: true,
        child: const OverlappingPair(),
      ),
      throwsA(isA<TestFailure>()),
    );

    final report = await tester.pumpAndAuditLayout(
      name: 'lenient',
      auditCase: _case,
      sink: sink,
      strict: false,
      child: const OverlappingPair(),
    );
    expect(report.countOf(LayoutSeverity.warning), 1);
  });

  testWidgets('wrap으로 감싼 앱 안에서 검사한다', (tester) async {
    const appKey = Key('app');
    final report = await tester.pumpAndAuditLayout(
      name: 'wrapped',
      auditCase: _case,
      sink: sink,
      wrap: (child) => MaterialApp(
        key: appKey,
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(body: child),
      ),
      child: const OverlappingPair(),
    );

    expect(find.byKey(appKey), findsOneWidget);
    expect(ofKind(report.findings, LayoutFindingKind.overlap), hasLength(1));
  });

  testWidgets('within으로 범위를 좁힌다', (tester) async {
    const cleanKey = Key('clean');
    final report = await tester.pumpAndAuditLayout(
      name: 'within',
      auditCase: _case,
      sink: sink,
      within: find.byKey(cleanKey),
      child: Column(
        children: [
          const OverlappingPair(),
          const Text('혼자 있는 글자', key: cleanKey, style: squareStyle),
        ],
      ),
    );

    expect(report.isEmpty, isTrue);
  });

  testWidgets('label은 보고서 제목의 조합 뒤에 붙는다', (tester) async {
    final report = await tester.pumpAndAuditLayout(
      name: 'labeled',
      auditCase: _case,
      label: '한국어 긴 문장',
      sink: sink,
      child: const OverlappingPair(),
    );

    expect(report.caseLabel, '$_case · 한국어 긴 문장');
  });

  testWidgets('ListTile 폭 단언 뒤 이어지는 레이아웃 오류도 넘침으로 흡수하고 보고한다', (
    tester,
  ) async {
    final report = await tester.pumpAndAuditLayout(
      name: 'list_tile',
      auditCase: _case,
      sink: sink,
      child: ListView(
        children: const [
          ListTile(
              title: Text('a', style: squareStyle),
              trailing: SizedBox(width: 400)),
        ],
      ),
    );

    expect(ofKind(report.findings, LayoutFindingKind.overflow), hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
