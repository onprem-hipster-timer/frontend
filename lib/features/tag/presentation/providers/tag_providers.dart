import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/tag/domain/tag_group_with_tags.dart';

part 'tag_providers.g.dart';

// ============================================================
// Base Data Provider (단일 API 호출)
// ============================================================

/// 태그 그룹+태그 원본 데이터 Provider
///
/// `readTagGroupsV1TagsGroupsGet()`이 그룹과 태그를 모두 포함하므로
/// 한 번의 API 호출로 모든 데이터를 가져옵니다.
@riverpod
Future<List<TagGroupReadWithTags>> tagGroupsRaw(Ref ref) async {
  final api = ref.watch(tagsApiProvider);

  try {
    return await api.readTagGroupsV1TagsGroupsGet();
  } catch (error) {
    throw Exception('태그 그룹 조회 실패: $error');
  }
}

// ============================================================
// Derived Providers (파생 데이터)
// ============================================================

extension on TagGroupReadWithTags {
  TagGroupRead toTagGroupRead() => TagGroupRead(
    id: id,
    name: name,
    color: color,
    createdAt: createdAt,
    updatedAt: updatedAt,
    description: description,
    goalRatios: goalRatios,
  );
}

/// 태그 그룹 목록 조회 Provider
///
/// 원본 데이터에서 TagGroupRead만 추출합니다.
@riverpod
Future<List<TagGroupRead>> tagGroups(Ref ref) async {
  final raw = await ref.watch(tagGroupsRawProvider.future);
  return raw.map((g) => g.toTagGroupRead()).toList();
}

/// 태그 트리 Provider
///
/// 원본 데이터에서 계층형 TagGroupWithTags로 변환합니다.
/// 태그가 없는 그룹도 포함됩니다.
@riverpod
Future<List<TagGroupWithTags>> tagTree(Ref ref) async {
  final raw = await ref.watch(tagGroupsRawProvider.future);

  final result = raw
      .map((g) => TagGroupWithTags(group: g.toTagGroupRead(), tags: g.tags))
      .toList();

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

      ref.invalidate(tagGroupsRawProvider);

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
  Future<TagGroupRead> updateGroup(
    String groupId,
    TagGroupUpdate data, {
    RequestOptions? options,
  }) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(tagsApiProvider);
      final result = await api.updateTagGroupV1TagsGroupsGroupIdPatch(
        groupId: groupId,
        body: data,
        options: options,
      );

      ref.invalidate(tagGroupsRawProvider);

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

      ref.invalidate(tagGroupsRawProvider);

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

      ref.invalidate(tagGroupsRawProvider);

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

      ref.invalidate(tagGroupsRawProvider);

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

      ref.invalidate(tagGroupsRawProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
