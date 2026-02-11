import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/api/export.dart';
import 'package:momeet/features/tag/domain/tag_group_with_tags.dart';

part 'tag_providers.g.dart';

// ============================================================
// Base Data Providers (API 조회)
// ============================================================

/// 태그 그룹 목록 조회 Provider
///
/// API에서 태그 그룹 목록만 조회합니다. (태그는 별도)
@riverpod
Future<List<TagGroupRead>> tagGroups(Ref ref) async {
  final api = ref.watch(tagsApiProvider);

  try {
    // TagGroupReadWithTags 대신 개별적으로 그룹과 태그를 조회
    final groupsWithTags = await api.readTagGroupsV1TagsGroupsGet();

    // TagGroupRead만 추출
    return groupsWithTags.map((groupWithTags) => TagGroupRead(
      id: groupWithTags.id,
      name: groupWithTags.name,
      color: groupWithTags.color,
      isTodoGroup: groupWithTags.isTodoGroup,
      createdAt: groupWithTags.createdAt,
      updatedAt: groupWithTags.updatedAt,
      description: groupWithTags.description,
      goalRatios: groupWithTags.goalRatios,
    )).toList();
  } catch (error) {
    throw Exception('태그 그룹 조회 실패: $error');
  }
}

/// 개별 태그 목록 조회 Provider
///
/// 모든 태그를 조회합니다. tagTree에서 그룹별로 분류됩니다.
@riverpod
Future<List<TagRead>> tags(Ref ref) async {
  final api = ref.watch(tagsApiProvider);

  try {
    final result = await api.readTagsV1TagsGet();
    return result;
  } catch (error) {
    throw Exception('태그 조회 실패: $error');
  }
}

// ============================================================
// Computed Provider (계층형 데이터)
// ============================================================

/// 태그 트리 Provider
///
/// tagGroups와 tags Provider를 watch하여 계층형 TagGroupWithTags 데이터를 제공합니다.
/// Left Join 방식으로 태그가 없는 그룹도 포함됩니다.
@riverpod
Future<List<TagGroupWithTags>> tagTree(Ref ref) async {
  // 두 Provider를 모두 watch
  final groups = await ref.watch(tagGroupsProvider.future);
  final allTags = await ref.watch(tagsProvider.future);

  // 각 그룹별로 해당하는 태그들을 분류
  final List<TagGroupWithTags> result = [];

  for (final group in groups) {
    // 이 그룹에 속한 태그들을 필터링
    final groupTags = allTags
        .where((tag) => tag.groupId == group.id)
        .toList();

    // 태그가 없는 그룹도 포함 (Left Join)
    result.add(TagGroupWithTags(
      group: group,
      tags: groupTags,
    ));
  }

  // 태그 개수 기준으로 정렬 (태그가 많은 그룹이 위로)
  result.sort((a, b) => b.tagCount.compareTo(a.tagCount));

  return result;
}

// ============================================================
// Mutation Provider (CRUD 작업)
// ============================================================

/// 태그 및 태그 그룹 변경 작업을 담당하는 Provider
///
/// 모든 CRUD 작업 후 관련 Provider들을 invalidate하여 UI를 자동 갱신합니다.
@riverpod
class TagMutations extends _$TagMutations {
  @override
  FutureOr<void> build() {}

  // ============================================================
  // Tag Group CRUD
  // ============================================================

  /// 태그 그룹 생성
  ///
  /// [data] 생성할 태그 그룹 데이터
  /// 성공 시 태그 그룹 목록을 새로고침합니다.
  Future<TagGroupRead> createGroup(TagGroupCreate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      final result = await api.createTagGroupV1TagsGroupsPost(body: data);

      // 관련 Provider들 새로고침
      ref.invalidate(tagGroupsProvider);
      ref.invalidate(tagTreeProvider); // 계층형 데이터도 갱신

      state = const AsyncValue.data(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 태그 그룹 수정
  ///
  /// [groupId] 수정할 그룹 ID
  /// [data] 수정할 데이터
  Future<TagGroupRead> updateGroup(String groupId, TagGroupUpdate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      final result = await api.updateTagGroupV1TagsGroupsGroupIdPatch(
        groupId: groupId,
        body: data,
      );

      // 관련 Provider들 새로고침
      ref.invalidate(tagGroupsProvider);
      ref.invalidate(tagTreeProvider);

      state = const AsyncValue.data(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 태그 그룹 삭제
  ///
  /// [groupId] 삭제할 그룹 ID
  /// 주의: CASCADE로 하위 태그들도 함께 삭제됩니다.
  Future<void> deleteGroup(String groupId) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      await api.deleteTagGroupV1TagsGroupsGroupIdDelete(groupId: groupId);

      // 그룹 삭제 시 태그 목록도 영향을 받으므로 모두 갱신
      ref.invalidate(tagGroupsProvider);
      ref.invalidate(tagsProvider);
      ref.invalidate(tagTreeProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  // ============================================================
  // Tag CRUD
  // ============================================================

  /// 태그 생성
  ///
  /// [data] 생성할 태그 데이터
  Future<TagRead> createTag(TagCreate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      final result = await api.createTagV1TagsPost(body: data);

      // 태그 관련 Provider들 새로고침
      ref.invalidate(tagsProvider);
      ref.invalidate(tagTreeProvider);

      state = const AsyncValue.data(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 태그 수정
  ///
  /// [tagId] 수정할 태그 ID
  /// [data] 수정할 데이터
  Future<TagRead> updateTag(String tagId, TagUpdate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      final result = await api.updateTagV1TagsTagIdPatch(
        tagId: tagId,
        body: data,
      );

      // 태그 관련 Provider들 새로고침
      ref.invalidate(tagsProvider);
      ref.invalidate(tagTreeProvider);

      state = const AsyncValue.data(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 태그 삭제
  ///
  /// [tagId] 삭제할 태그 ID
  Future<void> deleteTag(String tagId) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      await api.deleteTagV1TagsTagIdDelete(tagId: tagId);

      // 태그 관련 Provider들 새로고침
      ref.invalidate(tagsProvider);
      ref.invalidate(tagTreeProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
