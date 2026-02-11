import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/api/export.dart';

part 'tag_providers.g.dart';

// ============================================================
// Data Providers (API 조회)
// ============================================================

/// 태그 그룹 목록 조회 Provider (태그 포함)
///
/// API에서 태그가 포함된 태그 그룹 목록을 조회합니다.
@riverpod
Future<List<TagGroupReadWithTags>> tagGroups(Ref ref) async {
  final api = ref.watch(tagsApiProvider);

  try {
    final result = await api.readTagGroupsV1TagsGroupsGet();
    return result;
  } catch (error) {
    throw Exception('태그 그룹 조회 실패: $error');
  }
}

/// 개별 태그 목록 조회 Provider
///
/// 모든 태그를 개별적으로 조회합니다. (필터링 등에 사용)
@riverpod
Future<List<TagRead>> allTags(Ref ref) async {
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
/// tagGroups Provider를 watch하여 계층형 데이터를 제공합니다.
/// TagGroupReadWithTags가 이미 태그가 포함된 형태이므로 그대로 반환합니다.
@riverpod
Future<List<TagGroupReadWithTags>> tagTree(Ref ref) async {
  // TagGroupReadWithTags에는 이미 tags 필드가 포함되어 있음
  final tagGroups = await ref.watch(tagGroupsProvider.future);

  // 태그 개수 기준으로 정렬 (태그가 많은 그룹이 위로)
  final sortedGroups = [...tagGroups];
  sortedGroups.sort((a, b) => b.tags.length.compareTo(a.tags.length));

  return sortedGroups;
}

// ============================================================
// Mutation Provider (CRUD 작업)
// ============================================================

/// 태그 및 태그 그룹 변경 작업을 담당하는 Provider
@riverpod
class TagMutations extends _$TagMutations {
  @override
  FutureOr<void> build() {}

  // ============================================================
  // Tag Group CRUD
  // ============================================================

  /// 태그 그룹 생성
  Future<TagGroupRead> createGroup(TagGroupCreate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      final result = await api.createTagGroupV1TagsGroupsPost(body: data);

      // 태그 그룹 목록 새로고침
      ref.invalidate(tagGroupsProvider);

      state = const AsyncValue.data(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 태그 그룹 수정
  Future<TagGroupRead> updateGroup(String groupId, TagGroupUpdate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      final result = await api.updateTagGroupV1TagsGroupsGroupIdPatch(
        groupId: groupId,
        body: data,
      );

      // 태그 그룹 목록 새로고침
      ref.invalidate(tagGroupsProvider);

      state = const AsyncValue.data(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 태그 그룹 삭제
  ///
  /// 주의: CASCADE로 하위 태그들도 함께 삭제됩니다.
  Future<void> deleteGroup(String groupId) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      await api.deleteTagGroupV1TagsGroupsGroupIdDelete(groupId: groupId);

      // 태그 그룹 목록 새로고침
      ref.invalidate(tagGroupsProvider);
      ref.invalidate(allTagsProvider);

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
  Future<TagRead> createTag(TagCreate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      final result = await api.createTagV1TagsPost(body: data);

      // 태그 관련 목록 새로고침
      ref.invalidate(tagGroupsProvider);
      ref.invalidate(allTagsProvider);

      state = const AsyncValue.data(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 태그 수정
  Future<TagRead> updateTag(String tagId, TagUpdate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      final result = await api.updateTagV1TagsTagIdPatch(
        tagId: tagId,
        body: data,
      );

      // 태그 관련 목록 새로고침
      ref.invalidate(tagGroupsProvider);
      ref.invalidate(allTagsProvider);

      state = const AsyncValue.data(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 태그 삭제
  Future<void> deleteTag(String tagId) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      await api.deleteTagV1TagsTagIdDelete(tagId: tagId);

      // 태그 관련 목록 새로고침
      ref.invalidate(tagGroupsProvider);
      ref.invalidate(allTagsProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
