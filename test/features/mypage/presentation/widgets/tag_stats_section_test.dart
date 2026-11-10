import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/mypage/presentation/providers/my_page_providers.dart';
import 'package:momeet/features/mypage/presentation/widgets/tag_stats_section.dart';
import 'package:momeet/shared/ui/ui.dart';

import '../../../../helpers/layout_audit_app.dart';

Future<void> _pump(WidgetTester tester, Map<String, TagUsageItem> usage) async {
  await tester.pumpWidget(
    wrapWithApp(
      overrides: [
        tagUsageStatisticsProvider.overrideWith(
          (ref) async => TagUsageStatistics(tagUsageMap: usage),
        ),
      ],
    )(ListView(children: const [TagStatsSection()])),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('많이 쓴 태그 8개까지 이름과 횟수를 보인다', (tester) async {
    await _pump(tester, {
      for (var i = 0; i < 10; i++)
        'tag-$i': TagUsageItem(tagId: 'tag-$i', tagName: '태그$i', count: i + 1),
    });

    expect(find.text('태그9'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('태그2'), findsOneWidget);
    expect(find.text('태그1'), findsNothing);
    expect(find.text('태그0'), findsNothing);
  });

  testWidgets('쓴 태그가 없으면 빈 안내를 보인다', (tester) async {
    await _pump(tester, {});

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('아직 태그를 사용하지 않았습니다'), findsOneWidget);
  });
}
