// My Page Feature - Providers
//
// 마이페이지에서 사용하는 데이터를 관리하는 프로바이더들입니다.
// 사용자 프로필, 할 일 통계, 태그 사용 통계를 제공합니다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';

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

// ============================================================
// 데이터 프로바이더
// ============================================================

/// 사용자 프로필 데이터 프로바이더
///
/// 현재 로그인한 사용자의 이메일과 가입일 정보를 제공합니다.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return null;
  }

  // Supabase User 객체에서 생성일 파싱
  // user.createdAt은 String이므로 DateTime.parse()를 사용
  final createdAt = DateTime.parse(user.createdAt);

  return UserProfile(email: user.email ?? '', createdAt: createdAt);
});

/// 할 일 통계 데이터 프로바이더
///
/// 전체 할 일 목록을 불러와 상태별 집계를 클라이언트에서 계산합니다.
/// (`TodoStats`에는 아직 상태별 카운트가 없어 클라이언트 계산이 필요합니다.)
final todoStatisticsProvider = FutureProvider<TodoStatistics>((ref) async {
  return _calculateTodoStatisticsFromList(ref);
});

/// 클라이언트 측에서 할 일 통계 계산
Future<TodoStatistics> _calculateTodoStatisticsFromList(Ref ref) async {
  final todos = await ref.watch(allTodosProvider.future);

  int unscheduledCount = 0;
  int scheduledCount = 0;
  int doneCount = 0;
  int cancelledCount = 0;

  for (final todo in todos) {
    switch (todo.status) {
      case TodoStatus.unscheduled:
        unscheduledCount++;
        break;
      case TodoStatus.scheduled:
        scheduledCount++;
        break;
      case TodoStatus.done:
        doneCount++;
        break;
      case TodoStatus.cancelled:
        cancelledCount++;
        break;
      case TodoStatus.$unknown:
        // 알 수 없는 상태는 무시
        break;
    }
  }

  return TodoStatistics(
    totalCount: todos.length,
    unscheduledCount: unscheduledCount,
    scheduledCount: scheduledCount,
    doneCount: doneCount,
    cancelledCount: cancelledCount,
  );
}

/// 태그 사용 통계 데이터 프로바이더
///
/// 백엔드 통계 API에서 태그별 사용 통계를 가져옵니다.
/// API 실패 시 [AsyncValue.error]로 전파됩니다.
final tagUsageStatisticsProvider = FutureProvider<TagUsageStatistics>((
  ref,
) async {
  final api = ref.watch(todosApiProvider);
  final stats = await api.getTodoStatsV1TodosStatsGet();

  final tagUsageMap = <String, TagUsageItem>{};

  for (final tagStat in stats.byTag) {
    tagUsageMap[tagStat.tagId] = TagUsageItem(
      tagId: tagStat.tagId,
      tagName: tagStat.tagName,
      count: tagStat.count,
    );
  }

  return TagUsageStatistics(tagUsageMap: tagUsageMap);
});
