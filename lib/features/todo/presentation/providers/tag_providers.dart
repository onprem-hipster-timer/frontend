import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/api/export.dart';

part 'tag_providers.g.dart';

// ============================================================
// Tag Data Provider
// ============================================================

/// 태그 그룹 목록 조회 (태그 포함)
///
/// API에서 TagGroupReadWithTags 형태로 반환되므로
/// 이미 그룹별로 태그가 포함되어 있습니다.
@riverpod
Future<List<TagGroupReadWithTags>> tagGroups(Ref ref) async {
  final api = ref.watch(tagsApiProvider);
  try {
    final response = await api.readTagGroupsV1TagsGroupsGet();
    return response;
  } catch (error) {
    throw Exception('태그 그룹 조회 실패: $error');
  }
}

/// 특정 태그 그룹 조회 (태그 포함)
@riverpod
Future<TagGroupReadWithTags> tagGroup(
  Ref ref,
  String groupId,
) async {
  final api = ref.watch(tagsApiProvider);
  try {
    final response =
        await api.readTagGroupV1TagsGroupsGroupIdGet(groupId: groupId);
    return response;
  } catch (error) {
    throw Exception('태그 그룹 조회 실패: $error');
  }
}

// ============================================================
// Tag Mutation Provider
// ============================================================

/// 태그 관련 CUD 작업
@riverpod
class TagMutations extends _$TagMutations {
  @override
  FutureOr<void> build() {}

  /// 태그 그룹 생성
  Future<TagGroupRead> createTagGroup(TagGroupCreate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      final result = await api.createTagGroupV1TagsGroupsPost(body: data);

      state = const AsyncValue.data(null);

      // 태그 그룹 목록 새로고침
      ref.invalidate(tagGroupsProvider);

      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 태그 그룹 수정
  Future<TagGroupRead> updateTagGroup(
      String groupId, TagGroupUpdate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      final result = await api.updateTagGroupV1TagsGroupsGroupIdPatch(
        groupId: groupId,
        body: data,
      );

      state = const AsyncValue.data(null);

      // 관련 데이터 새로고침
      ref.invalidate(tagGroupsProvider);
      ref.invalidate(tagGroupProvider(groupId));

      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 태그 그룹 삭제
  Future<void> deleteTagGroup(String groupId) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      await api.deleteTagGroupV1TagsGroupsGroupIdDelete(groupId: groupId);

      state = const AsyncValue.data(null);

      // 태그 그룹 목록 새로고침
      ref.invalidate(tagGroupsProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 태그 생성
  Future<TagRead> createTag(TagCreate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      final result = await api.createTagV1TagsPost(body: data);

      state = const AsyncValue.data(null);

      // 관련 데이터 새로고침
      ref.invalidate(tagGroupsProvider);
      ref.invalidate(tagGroupProvider(data.groupId));

      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 태그 수정 (그룹 이동 포함)
  Future<TagRead> updateTag(String tagId, TagUpdate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      final result = await api.updateTagV1TagsTagIdPatch(
        tagId: tagId,
        body: data,
      );

      state = const AsyncValue.data(null);

      // 모든 태그 그룹 새로고침 (그룹 이동 가능성)
      ref.invalidate(tagGroupsProvider);

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

      state = const AsyncValue.data(null);

      // 모든 태그 그룹 새로고침
      ref.invalidate(tagGroupsProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

// ============================================================
// UI State Provider
// ============================================================

/// 태그 트리 확장 상태 관리
@riverpod
class TagTreeExpansion extends _$TagTreeExpansion {
  @override
  Map<String, bool> build() => {};

  /// 그룹 확장/축소 토글
  void toggleGroup(String groupId) {
    state = {
      ...state,
      groupId: !(state[groupId] ?? false),
    };
  }

  /// 그룹 확장 상태 설정
  void setGroupExpanded(String groupId, bool expanded) {
    state = {
      ...state,
      groupId: expanded,
    };
  }

  /// 모든 그룹 확장
  void expandAll(List<String> groupIds) {
    state = {
      for (final groupId in groupIds) groupId: true,
    };
  }

  /// 모든 그룹 축소
  void collapseAll() {
    state = {};
  }
}
