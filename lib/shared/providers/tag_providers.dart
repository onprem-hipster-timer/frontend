import 'package:dio/dio.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/tag_group_with_tags.dart';

part 'tag_providers.g.dart';

// ============================================================
// Base Data + CUD Notifier
// ============================================================

/// 태그 그룹+태그 원본 데이터와 CUD side-effect를 함께 소유하는 Notifier.
///
/// 설계 원칙(#66):
/// - "데이터 캐시 + side-effect 실행"은 이 notifier가 책임진다. CUD 메서드는
///   API 호출 후 `invalidateSelf()`로 목록을 갱신한다.
/// - "UI operation state(pending/error/success)"는 이 클래스가 아니라 아래의
///   [Mutation]들이 책임진다. 따라서 작업 상태 전용 notifier(과거 `TagMutations`)는
///   두지 않는다.
/// - CUD는 항상 `mutation.run(ref, (tsx) => tsx.get(tagGroupsRawProvider.notifier)
///   .xxx())` 형태로 호출한다. `tsx.get`이 run 동안 이 provider를 alive로 유지하므로,
///   호출한 화면이 먼저 dispose돼도 API 완료 후 `invalidateSelf()`가 정상 실행된다
///   (= dispose 이후 캐시 갱신 누락이 사라진다). 그래서 메서드마다 `ref.mounted`
///   가드를 반복할 필요가 없다.
///
/// generated REST client(`tagsApiProvider`)은 자동 생성물이라 수정하지 않고,
/// 그 위에서 우리가 소유하는 이 계층으로만 감싼다.
@riverpod
class TagGroupsRaw extends _$TagGroupsRaw {
  @override
  Future<List<TagGroupReadWithTags>> build() async {
    final api = ref.watch(tagsApiProvider);

    try {
      return await api.readTagGroupsV1TagsGroupsGet();
    } catch (error) {
      throw Exception('태그 그룹 조회 실패: $error');
    }
  }

  // ----- Tag Group CUD -----

  /// 태그 그룹 생성
  Future<void> createGroup(TagGroupCreate data) async {
    await ref.read(tagsApiProvider).createTagGroupV1TagsGroupsPost(body: data);
    ref.invalidateSelf();
  }

  /// 태그 그룹 수정
  Future<void> updateGroup(
    String groupId,
    TagGroupUpdate data, {
    RequestOptions? options,
  }) async {
    await ref
        .read(tagsApiProvider)
        .updateTagGroupV1TagsGroupsGroupIdPatch(
          groupId: groupId,
          body: data,
          options: options,
        );
    ref.invalidateSelf();
  }

  /// 태그 그룹 삭제 (CASCADE로 하위 태그도 함께 삭제됨)
  Future<void> deleteGroup(String groupId) async {
    await ref
        .read(tagsApiProvider)
        .deleteTagGroupV1TagsGroupsGroupIdDelete(groupId: groupId);
    ref.invalidateSelf();
  }

  // ----- Tag CUD -----

  /// 태그 생성
  Future<void> createTag(TagCreate data) async {
    await ref.read(tagsApiProvider).createTagV1TagsPost(body: data);
    ref.invalidateSelf();
  }

  /// 태그 수정 (그룹 이동 포함)
  Future<void> updateTag(String tagId, TagUpdate data) async {
    await ref
        .read(tagsApiProvider)
        .updateTagV1TagsTagIdPatch(tagId: tagId, body: data);
    ref.invalidateSelf();
  }

  /// 태그 삭제
  Future<void> deleteTag(String tagId) async {
    await ref.read(tagsApiProvider).deleteTagV1TagsTagIdDelete(tagId: tagId);
    ref.invalidateSelf();
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
// Mutations (UI operation state)
// ============================================================

/// 태그/태그 그룹 CUD의 UI 작업 상태(pending/error/success)를 담는 Mutation들.
///
/// 사용 예:
/// ```dart
/// // 상태 구독
/// final isDeleting = ref.watch(deleteTagGroupMutation).isPending;
/// // 실행
/// await deleteTagGroupMutation.run(
///   ref,
///   (tsx) => tsx.get(tagGroupsRawProvider.notifier).deleteGroup(id),
/// );
/// ```
final createTagGroupMutation = Mutation<void>(label: 'createTagGroup');
final updateTagGroupMutation = Mutation<void>(label: 'updateTagGroup');
final deleteTagGroupMutation = Mutation<void>(label: 'deleteTagGroup');
final createTagMutation = Mutation<void>(label: 'createTag');
final updateTagMutation = Mutation<void>(label: 'updateTag');
final deleteTagMutation = Mutation<void>(label: 'deleteTag');
