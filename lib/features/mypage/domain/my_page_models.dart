// My Page Feature - Models
//
// 마이페이지에 보이는 사용자 프로필, 할 일 통계, 태그 사용 통계입니다.

// ============================================================
// 사용자 프로필 모델
// ============================================================

/// 마이페이지용 사용자 프로필 데이터
class UserProfile {
  final String email;
  final DateTime createdAt;

  const UserProfile({required this.email, required this.createdAt});
}

// ============================================================
// 할 일 통계 모델
// ============================================================

/// 할 일 상태별 통계
class TodoStatistics {
  final int totalCount;
  final int unscheduledCount;
  final int scheduledCount;
  final int doneCount;
  final int cancelledCount;

  const TodoStatistics({
    required this.totalCount,
    required this.unscheduledCount,
    required this.scheduledCount,
    required this.doneCount,
    required this.cancelledCount,
  });

  /// 완료율 계산 (0.0 ~ 1.0)
  double get completionRate {
    if (totalCount == 0) return 0.0;
    return doneCount / totalCount;
  }

  /// 완료율 백분율 (0 ~ 100)
  int get completionPercentage {
    return (completionRate * 100).round();
  }
}

// ============================================================
// 태그 사용 통계 모델
// ============================================================

/// 태그별 사용 통계
class TagUsageStatistics {
  final Map<String, TagUsageItem> tagUsageMap;

  const TagUsageStatistics({required this.tagUsageMap});

  /// 태그 목록을 사용 빈도순으로 정렬하여 반환
  List<TagUsageItem> get sortedByUsage {
    final items = tagUsageMap.values.toList();
    items.sort((a, b) => b.count.compareTo(a.count));
    return items;
  }

  /// 상위 N개 태그 반환
  List<TagUsageItem> getTopTags(int limit) {
    final sorted = sortedByUsage;
    return sorted.take(limit).toList();
  }
}

/// 개별 태그 사용 통계
class TagUsageItem {
  final String tagId;
  final String tagName;
  final int count;

  const TagUsageItem({
    required this.tagId,
    required this.tagName,
    required this.count,
  });
}
