import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:momeet/features/mypage/presentation/providers/my_page_providers.dart';
import 'package:momeet/features/mypage/presentation/widgets/tag_stats_section.dart';

import '../../../../helpers/layout_audit_app.dart';

void main() {
  testLayoutAudit(
    'tag_stats_section',
    subject: '태그 이름',
    within: find.byType(TagStatsSection),
    build: (text) =>
        wrapWithApp(
          overrides: [
            tagUsageStatisticsProvider.overrideWith(
              (ref) async => _statsWith(text.value),
            ),
          ],
        )(
          // 마이페이지와 같은 패딩의 ListView 안에 둔다.
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: const [TagStatsSection()],
          ),
        ),
    verify: (tester) {
      expect(find.byType(TagStatsSection), findsOneWidget);
    },
  );
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
