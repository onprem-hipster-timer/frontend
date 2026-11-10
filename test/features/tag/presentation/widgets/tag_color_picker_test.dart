import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/tag/presentation/utils/tag_color_palette.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_color_picker.dart';

void main() {
  testWidgets('색을 누르면 그 색을 알리고, 고른 색에만 체크를 보인다', (tester) async {
    var selected = TagColorPalette.colors.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => TagColorPicker(
              selected: selected,
              onChanged: (color) => setState(() => selected = color),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('색 1')),
      matchesSemantics(
        label: '색 1',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.bySemanticsLabel('색 3'));
    await tester.pump();

    expect(selected, TagColorPalette.colors[2]);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('색 1')),
      isNot(matchesSemantics(isSelected: true)),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('색 3')),
      matchesSemantics(
        label: '색 3',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
  });
}
