import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/mypage/presentation/providers/my_page_providers.dart';

void main() {
  // ============================================================
  // TodoStatistics
  // ============================================================
  group('TodoStatistics', () {
    test('completionRate은 doneCount / totalCount이다', () {
      const stats = TodoStatistics(
        totalCount: 10,
        unscheduledCount: 2,
        scheduledCount: 3,
        doneCount: 4,
        cancelledCount: 1,
      );

      expect(stats.completionRate, 0.4);
    });

    test('totalCount가 0이면 completionRate은 0.0이다', () {
      const stats = TodoStatistics(
        totalCount: 0,
        unscheduledCount: 0,
        scheduledCount: 0,
        doneCount: 0,
        cancelledCount: 0,
      );

      expect(stats.completionRate, 0.0);
    });

    test('completionPercentage는 반올림된 백분율이다', () {
      const stats = TodoStatistics(
        totalCount: 3,
        unscheduledCount: 1,
        scheduledCount: 1,
        doneCount: 1,
        cancelledCount: 0,
      );

      // 1/3 = 33.33...% → 33
      expect(stats.completionPercentage, 33);
    });

    test('모두 완료된 경우 completionPercentage는 100이다', () {
      const stats = TodoStatistics(
        totalCount: 5,
        unscheduledCount: 0,
        scheduledCount: 0,
        doneCount: 5,
        cancelledCount: 0,
      );

      expect(stats.completionPercentage, 100);
    });
  });

  // ============================================================
  // TagUsageStatistics
  // ============================================================
  group('TagUsageStatistics', () {
    test('sortedByUsage는 count 내림차순으로 정렬한다', () {
      final stats = TagUsageStatistics(
        tagUsageMap: {
          'a': const TagUsageItem(tagId: 'a', tagName: 'A', count: 1),
          'b': const TagUsageItem(tagId: 'b', tagName: 'B', count: 5),
          'c': const TagUsageItem(tagId: 'c', tagName: 'C', count: 3),
        },
      );

      final sorted = stats.sortedByUsage;
      expect(sorted[0].tagName, 'B');
      expect(sorted[1].tagName, 'C');
      expect(sorted[2].tagName, 'A');
    });

    test('getTopTags는 상위 N개만 반환한다', () {
      final stats = TagUsageStatistics(
        tagUsageMap: {
          'a': const TagUsageItem(tagId: 'a', tagName: 'A', count: 10),
          'b': const TagUsageItem(tagId: 'b', tagName: 'B', count: 5),
          'c': const TagUsageItem(tagId: 'c', tagName: 'C', count: 3),
          'd': const TagUsageItem(tagId: 'd', tagName: 'D', count: 1),
        },
      );

      final top2 = stats.getTopTags(2);
      expect(top2.length, 2);
      expect(top2[0].tagName, 'A');
      expect(top2[1].tagName, 'B');
    });

    test('getTopTags에 전체 개수보다 큰 limit을 주면 전체를 반환한다', () {
      final stats = TagUsageStatistics(
        tagUsageMap: {
          'a': const TagUsageItem(tagId: 'a', tagName: 'A', count: 1),
        },
      );

      expect(stats.getTopTags(10).length, 1);
    });

    test('빈 tagUsageMap이면 sortedByUsage는 빈 리스트이다', () {
      const stats = TagUsageStatistics(tagUsageMap: {});

      expect(stats.sortedByUsage, isEmpty);
      expect(stats.getTopTags(5), isEmpty);
    });
  });

  // ============================================================
  // UserProfile
  // ============================================================
  group('UserProfile', () {
    test('email과 createdAt을 올바르게 저장한다', () {
      final date = DateTime(2024, 1, 15);
      final profile = UserProfile(email: 'test@test.com', createdAt: date);

      expect(profile.email, 'test@test.com');
      expect(profile.createdAt, date);
    });
  });
}
