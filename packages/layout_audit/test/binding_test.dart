import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

import 'recorded_reports.dart';
import 'support.dart';

const _audited = '테스트가 끝나면 남은 트리를 자동으로 감사한다 (자동 감사 대상 1)';
const _skipped = '자동 감사 제외: 이 테스트는 감사하지 않는다';
const _clean = '겹침이 없는 트리는 빈 보고서를 남긴다 (자동 감사 대상 2)';
const _overflow = 'RenderFlex 넘침은 기록하면서 테스트 실패도 그대로 남긴다 (자동 감사 대상 3)';
const _failing = '감사 중 예외가 나도 테스트는 통과한다 (자동 감사 대상 4)';

List<LayoutReport> _reportsOf(String description) =>
    recordedReports.where((r) => r.name == slugify(description)).toList();

void main() {
  testWidgets(_audited, (tester) async {
    await pumpInApp(tester, const OverlappingPair());
  });

  testWidgets(_skipped, (tester) async {
    await pumpInApp(tester, const OverlappingPair());
  });

  testWidgets(_clean, (tester) async {
    await pumpInApp(
      tester,
      const Row(
        children: [
          Text('AAAA', style: squareStyle),
          Text('BBBB', style: squareStyle)
        ],
      ),
    );
  });

  testWidgets(_overflow, (tester) async {
    await pumpInApp(
      tester,
      const Row(children: [SizedBox(width: 500, height: 10)]),
    );

    expect(tester.takeException(), isNotNull);
  });

  testWidgets(_failing, (tester) async {
    throwInIgnore = true;
    addTearDown(() => throwInIgnore = false);
    await pumpInApp(tester, const OverlappingPair());
  });

  tearDownAll(() {
    final audited = _reportsOf(_audited);
    expect(audited, hasLength(1));
    final findings = audited.single.findings;
    expect(findings, hasLength(1));
    expect(findings.single.kind, LayoutFindingKind.overlap);
    expect(audited.single.caseLabel, contains('360x800'));

    expect(
      recordedReports.where((r) => r.name.contains(slugify('자동 감사 제외'))),
      isEmpty,
    );

    final clean = _reportsOf(_clean);
    expect(clean, hasLength(1));
    expect(clean.single.isEmpty, isTrue);

    final overflow = _reportsOf(_overflow);
    expect(overflow, hasLength(1));
    expect(
      overflow.single.findings
          .where((f) => f.kind == LayoutFindingKind.overflow),
      hasLength(1),
    );

    final failing = _reportsOf(_failing);
    expect(failing, hasLength(1));
    expect(
      failing.single.findings.map((f) => (f.severity, f.message)),
      contains(
        isA<(LayoutSeverity, String)>()
            .having((r) => r.$1, 'severity', LayoutSeverity.info)
            .having((r) => r.$2, 'message', contains('점검 실패')),
      ),
    );
  });

  group('parseMatrixEnvironment', () {
    test('뷰포트만 주면 논리 크기만 읽는다', () {
      final m = LayoutAuditBinding.parseMatrixEnvironment(
        {'LAYOUT_AUDIT_VIEWPORT': '320x568'},
      );
      expect(m.logicalSize, const Size(320, 568));
      expect(m.dpr, isNull);
      expect(m.textScale, isNull);
    });

    test('@ 뒤의 값을 기기 픽셀 비율로 읽는다', () {
      final m = LayoutAuditBinding.parseMatrixEnvironment({
        'LAYOUT_AUDIT_VIEWPORT': '320x568@2.5',
        'LAYOUT_AUDIT_TEXT_SCALE': '2.0',
      });
      expect(m.logicalSize, const Size(320, 568));
      expect(m.dpr, 2.5);
      expect(m.textScale, 2.0);
    });

    test('형식이 틀리거나 0 이하인 값은 무시한다', () {
      for (final env in [
        {'LAYOUT_AUDIT_VIEWPORT': 'abc', 'LAYOUT_AUDIT_TEXT_SCALE': 'x'},
        {'LAYOUT_AUDIT_VIEWPORT': '320x', 'LAYOUT_AUDIT_TEXT_SCALE': ''},
        {'LAYOUT_AUDIT_VIEWPORT': '0x568', 'LAYOUT_AUDIT_TEXT_SCALE': '0'},
        {'LAYOUT_AUDIT_VIEWPORT': '320x568@', 'LAYOUT_AUDIT_TEXT_SCALE': '-1'},
        {'LAYOUT_AUDIT_VIEWPORT': '320x568@0'},
      ]) {
        final m = LayoutAuditBinding.parseMatrixEnvironment(env);
        expect(m.logicalSize, isNull, reason: '$env');
        expect(m.dpr, isNull, reason: '$env');
        expect(m.textScale, isNull, reason: '$env');
      }
    });

    test('키가 없으면 모두 null이다', () {
      final m = LayoutAuditBinding.parseMatrixEnvironment(const {});
      expect(m.logicalSize, isNull);
      expect(m.dpr, isNull);
      expect(m.textScale, isNull);
    });
  });

  test('LAYOUT_AUDIT=off일 때만 꺼진다', () {
    expect(LayoutAuditBinding.isDisabled({'LAYOUT_AUDIT': 'off'}), isTrue);
    expect(LayoutAuditBinding.isDisabled({'LAYOUT_AUDIT': 'on'}), isFalse);
    expect(LayoutAuditBinding.isDisabled(const {}), isFalse);
  });

  // 다른 바인딩이 먼저 설치된 경우는 이 프로세스에 이미 이 바인딩이 있어 재현할 수 없다.
  test('ensureInitialized를 다시 불러도 같은 바인딩을 돌려준다', () {
    expect(
      LayoutAuditBinding.ensureInitialized(),
      same(LayoutAuditBinding.instance),
    );
    expect(TestWidgetsFlutterBinding.ensureInitialized(),
        same(LayoutAuditBinding.instance));
  });
}
