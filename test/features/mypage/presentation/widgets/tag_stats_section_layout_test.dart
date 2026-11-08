import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:momeet/features/mypage/presentation/providers/my_page_providers.dart';
import 'package:momeet/features/mypage/presentation/widgets/tag_stats_section.dart';

import '../../../../helpers/layout_audit_app.dart';

void main() {
  for (final text in StressTexts.all) {
    testWidgets(
      '${text.label} 태그 이름에서 겹침·넘침·잘림을 보고한다',
      variant: LayoutAuditVariants.all,
      (tester) async {
        final auditCase = LayoutAuditVariants.all.currentValue!;
        final stats = _statsWith(text.value);

        await tester.pumpAndAuditLayout(
          name: 'tag_stats_section',
          auditCase: auditCase,
          label: text.label,
          wrap: wrapWithApp(
            overrides: [
              tagUsageStatisticsProvider.overrideWith((ref) async => stats),
            ],
          ),
          within: find.byType(TagStatsSection),
          // 마이페이지와 같은 패딩의 ListView 안에 둔다.
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: const [TagStatsSection()],
          ),
        );

        expect(find.byType(TagStatsSection), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

TagUsageStatistics _statsWith(String stressName) {
  return TagUsageStatistics(
    tagUsageMap: {
      for (var i = 0; i < 8; i++)
        'tag-$i': TagUsageItem(
          tagId: 'tag-$i',
          tagName: i.isEven ? stressName : '태그$i',
          count: 1234 - i,
        ),
    },
  );
}
