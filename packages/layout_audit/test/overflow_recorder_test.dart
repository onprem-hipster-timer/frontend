import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

import 'support.dart';

/// 크기는 정한 뒤 레이아웃 중에 던져 다른 후속 오류 없이 렌더링 오류 하나만 낸다.
class _ThrowingLayout extends LeafRenderObjectWidget {
  const _ThrowingLayout();

  @override
  RenderObject createRenderObject(BuildContext context) => _ThrowingBox();
}

class _ThrowingBox extends RenderBox {
  @override
  void performLayout() {
    size = constraints.smallest;
    throw StateError('독립 레이아웃 오류');
  }
}

class _Throwing extends StatelessWidget {
  const _Throwing();

  @override
  Widget build(BuildContext context) => throw StateError('빌드 실패');
}

void main() {
  testWidgets('RenderFlex 넘침을 실패 대신 기록한다', (tester) async {
    final findings = await recordLayoutOverflows(
      () => pumpInApp(
        tester,
        const Row(children: [SizedBox(width: 500, height: 10)]),
      ),
    );

    expect(findings, hasLength(1));
    final overflow = findings.single;
    expect(overflow.kind, LayoutFindingKind.overflow);
    expect(overflow.severity, LayoutSeverity.warning);
    expect(overflow.message, startsWith('[넘침] '));
    expect(overflow.message, contains('Row가 오른쪽으로 140.0px 넘칩니다'));
    expect(
      overflow.locations.single.toString(),
      matches(RegExp(r'^test/overflow_recorder_test\.dart:\d+$')),
    );
    expect(overflow.message, contains(overflow.locations.single.toString()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('세로 넘침은 아래쪽으로 기록한다', (tester) async {
    final findings = await recordLayoutOverflows(
      () => pumpInApp(
        tester,
        const SizedBox(
          height: 100,
          child: Column(children: [SizedBox(width: 10, height: 150)]),
        ),
      ),
    );

    expect(findings.single.message, contains('Column가 아래쪽으로 50.0px 넘칩니다'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('forward가 true면 기록하면서 원래 핸들러에도 넘긴다', (tester) async {
    final findings = await recordLayoutOverflows(
      () => pumpInApp(
        tester,
        const Row(children: [SizedBox(width: 500, height: 10)]),
      ),
      forward: true,
    );

    expect(findings, hasLength(1));
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('넘침이 아닌 오류는 그대로 테스트 프레임워크로 넘긴다', (tester) async {
    final findings = await recordLayoutOverflows(
      () => pumpInApp(tester, const _Throwing()),
    );

    expect(findings, isEmpty);
    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('ListTile 폭 단언을 넘침으로 기록한다', (tester) async {
    final findings = await recordLayoutOverflows(
      () => pumpInApp(
        tester,
        const ListTile(title: Text('a'), trailing: SizedBox(width: 400)),
      ),
    );

    expect(findings, hasLength(1));
    expect(findings.single.kind, LayoutFindingKind.overflow);
    expect(findings.single.message, contains('타일 폭'));
    // 단언이 레이아웃을 중단시켜 뒤따르는 오류는 같은 원인으로 보고 삼킨다.
    expect(tester.takeException(), isNull);
  });

  testWidgets('body가 예외를 던져도 핸들러를 되돌린다', (tester) async {
    final before = FlutterError.onError;

    await expectLater(
      recordLayoutOverflows(() async => throw StateError('본문 실패')),
      throwsStateError,
    );

    expect(FlutterError.onError, same(before));
  });

  testWidgets('ListTile 단언 뒤 다른 프레임에서 난 렌더링 오류는 삼키지 않는다', (tester) async {
    final findings = await recordLayoutOverflows(() async {
      await pumpInApp(
        tester,
        const ListTile(title: Text('a'), trailing: SizedBox(width: 400)),
      );
      await tester.pumpWidget(const MaterialApp(home: _ThrowingLayout()));
    });

    expect(findings, hasLength(1));
    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('망가진 ListTile이 남아 있어도 다른 곳에서 새로 난 렌더링 오류는 삼키지 않는다', (
    tester,
  ) async {
    // ListTile은 스크롤 뷰 안에 가둬 두어 실패가 바깥 Column까지 번지지 않게 한다.
    Widget scene({required bool withSibling}) => Column(
          children: [
            Expanded(
              child: ListView(
                children: const [
                  ListTile(title: Text('a'), trailing: SizedBox(width: 400)),
                ],
              ),
            ),
            if (withSibling) const _ThrowingLayout(),
          ],
        );

    final findings = await recordLayoutOverflows(() async {
      await pumpInApp(tester, scene(withSibling: false));
      await pumpInApp(tester, scene(withSibling: true));
    });

    expect(findings, hasLength(1));
    expect(tester.takeException(), isA<StateError>());
  });
}
