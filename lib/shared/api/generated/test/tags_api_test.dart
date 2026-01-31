import 'package:test/test.dart';
import 'package:momeet_api/momeet_api.dart';


/// tests for TagsApi
void main() {
  final instance = MomeetApi().getTagsApi();

  group(TagsApi, () {
    // Create Tag Group
    //
    // 태그 그룹 생성
    //
    //Future<TagGroupRead> createTagGroupV1TagsGroupsPost(TagGroupCreate tagGroupCreate) async
    test('test createTagGroupV1TagsGroupsPost', () async {
      // TODO
    });

    // Create Tag
    //
    // 태그 생성
    //
    //Future<TagRead> createTagV1TagsPost(TagCreate tagCreate) async
    test('test createTagV1TagsPost', () async {
      // TODO
    });

    // Delete Tag Group
    //
    // 태그 그룹 삭제 (CASCADE로 태그도 삭제)
    //
    //Future<JsonObject> deleteTagGroupV1TagsGroupsGroupIdDelete(String groupId) async
    test('test deleteTagGroupV1TagsGroupsGroupIdDelete', () async {
      // TODO
    });

    // Delete Tag
    //
    // 태그 삭제
    //
    //Future<JsonObject> deleteTagV1TagsTagIdDelete(String tagId) async
    test('test deleteTagV1TagsTagIdDelete', () async {
      // TODO
    });

    // Read Tag Group
    //
    // 태그 그룹 조회 (태그 포함)
    //
    //Future<TagGroupReadWithTags> readTagGroupV1TagsGroupsGroupIdGet(String groupId) async
    test('test readTagGroupV1TagsGroupsGroupIdGet', () async {
      // TODO
    });

    // Read Tag Groups
    //
    // 모든 태그 그룹 조회 (태그 포함)
    //
    //Future<BuiltList<TagGroupReadWithTags>> readTagGroupsV1TagsGroupsGet() async
    test('test readTagGroupsV1TagsGroupsGet', () async {
      // TODO
    });

    // Read Tag
    //
    // 태그 조회
    //
    //Future<TagRead> readTagV1TagsTagIdGet(String tagId) async
    test('test readTagV1TagsTagIdGet', () async {
      // TODO
    });

    // Read Tags
    //
    // 모든 태그 조회
    //
    //Future<BuiltList<TagRead>> readTagsV1TagsGet() async
    test('test readTagsV1TagsGet', () async {
      // TODO
    });

    // Update Tag Group
    //
    // 태그 그룹 업데이트
    //
    //Future<TagGroupRead> updateTagGroupV1TagsGroupsGroupIdPatch(String groupId, TagGroupUpdate tagGroupUpdate) async
    test('test updateTagGroupV1TagsGroupsGroupIdPatch', () async {
      // TODO
    });

    // Update Tag
    //
    // 태그 업데이트
    //
    //Future<TagRead> updateTagV1TagsTagIdPatch(String tagId, TagUpdate tagUpdate) async
    test('test updateTagV1TagsTagIdPatch', () async {
      // TODO
    });

  });
}
