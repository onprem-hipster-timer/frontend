import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:material_ui/material_ui.dart';

class _Swap extends StatelessWidget {
  const _Swap({required this.second});

  final bool second;

  /// 아래 두 Text가 놓인 줄
  static const firstLine = 20;
  static const secondLine = 18;

  @override
  Widget build(BuildContext context) {
    if (second) {
      return const Text('둘째');
    }
    return const Text('첫째');
  }
}

void main() {
  testWidgets('다시 그려 같은 렌더 객체에 다른 위젯이 붙으면 새 위젯의 위치를 돌려준다', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: _Swap(second: false),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(find.text('첫째'));
    expect(sourceLocationOf(paragraph)?.line, _Swap.firstLine);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: _Swap(second: true),
      ),
    );

    expect(tester.renderObject(find.text('둘째')), same(paragraph));
    expect(sourceLocationOf(paragraph)?.line, _Swap.secondLine);
  });
}
