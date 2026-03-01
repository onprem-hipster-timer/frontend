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

  const UserProfile({
    required this.email,
    required this.createdAt,
  });
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

  return UserProfile(
    email: user.email ?? '',
    createdAt: createdAt,
  );
});

/// 할 일 통계 데이터 프로바이더
///
/// 백엔드에 통계 API가 있다면 이를 사용하고,
/// 없다면 모든 할 일 목록을 가져와서 클라이언트 측에서 계산합니다.
final todoStatisticsProvider = FutureProvider<TodoStatistics>((ref) async {
  try {
    // 백엔드 통계 API를 먼저 시도
    final api = ref.watch(todosApiProvider);
    await api.getTodoStatsV1TodosStatsGet(); // 통계 API 호출 시도

    // API 응답을 우리 모델로 변환
    // 현재 TodoStats 모델에는 상태별 개수가 없으므로
    // 전체 할 일을 가져와서 클라이언트 측에서 계산
    // 백엔드 통계가 확장되면 이 부분을 수정할 수 있습니다.
    return _calculateTodoStatisticsFromList(ref);
  } catch (e) {
    // 통계 API가 실패하면 전체 목록을 가져와서 계산
    return _calculateTodoStatisticsFromList(ref);
  }
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
/// 백엔드 통계가 있다면 사용하고, 없다면 클라이언트 측에서 계산합니다.
final tagUsageStatisticsProvider =
    FutureProvider<TagUsageStatistics>((ref) async {
  try {
    // 백엔드 통계 API 시도
    final api = ref.watch(todosApiProvider);
    final stats = await api.getTodoStatsV1TodosStatsGet();

    // API 응답의 byTag를 우리 모델로 변환
    final tagUsageMap = <String, TagUsageItem>{};

    for (final tagStat in stats.byTag) {
      tagUsageMap[tagStat.tagId] = TagUsageItem(
        tagId: tagStat.tagId,
        tagName: tagStat.tagName,
        count: tagStat.count,
      );
    }

    return TagUsageStatistics(tagUsageMap: tagUsageMap);
  } catch (e) {
    // 통계 API가 실패하면 클라이언트 측에서 계산
    return _calculateTagUsageFromTodos(ref);
  }
});

/// 클라이언트 측에서 태그 사용 통계 계산
Future<TagUsageStatistics> _calculateTagUsageFromTodos(Ref ref) async {
  final todos = await ref.watch(allTodosProvider.future);

  // 태그 그룹을 TagGroupReadWithTags 타입으로 가져오기
  try {
    final api = ref.watch(tagsApiProvider);
    final tagGroups = await api.readTagGroupsV1TagsGroupsGet();

    // 태그 ID -> 사용 횟수 맵
    final tagCountMap = <String, int>{};

    // 모든 할 일을 순회하며 태그 사용 횟수 계산
    for (final todo in todos) {
      for (final tag in todo.tags) {
        tagCountMap[tag.id] = (tagCountMap[tag.id] ?? 0) + 1;
      }
    }

    // 태그 ID -> 태그 이름 맵 생성
    final tagNameMap = <String, String>{};
    for (final group in tagGroups) {
      for (final tag in group.tags) {
        tagNameMap[tag.id] = tag.name;
      }
    }

    // 최종 결과 맵 생성
    final tagUsageMap = <String, TagUsageItem>{};
    for (final entry in tagCountMap.entries) {
      final tagId = entry.key;
      final count = entry.value;
      final tagName = tagNameMap[tagId] ?? 'Unknown Tag';

      tagUsageMap[tagId] = TagUsageItem(
        tagId: tagId,
        tagName: tagName,
        count: count,
      );
    }

    return TagUsageStatistics(tagUsageMap: tagUsageMap);
  } catch (e) {
    // API 호출 실패 시 빈 통계 반환
    return const TagUsageStatistics(tagUsageMap: {});
  }
}
