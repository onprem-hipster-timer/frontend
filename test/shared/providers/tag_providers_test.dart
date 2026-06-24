import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/providers/tag_providers.dart';

class MockTagsClient extends Mock implements TagsClient {}

class FakeTagGroupCreate extends Fake implements TagGroupCreate {}

class FakeTagGroupUpdate extends Fake implements TagGroupUpdate {}

class FakeTagCreate extends Fake implements TagCreate {}

class FakeTagUpdate extends Fake implements TagUpdate {}

TagGroupReadWithTags _group(
  String id,
  String name, {
  List<TagRead> tags = const [],
}) {
  return TagGroupReadWithTags(
    id: id,
    name: name,
    color: '#3498DB',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    tags: tags,
  );
}

TagRead _tag(String id, String groupId) {
  return TagRead(
    id: id,
    name: 'tag-$id',
    color: '#FF5733',
    groupId: groupId,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

void main() {
  late MockTagsClient api;

  setUpAll(() {
    registerFallbackValue(FakeTagGroupCreate());
    registerFallbackValue(FakeTagGroupUpdate());
    registerFallbackValue(FakeTagCreate());
    registerFallbackValue(FakeTagUpdate());
  });

  setUp(() {
    api = MockTagsClient();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [tagsApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    return container;
  }

  void stubRead(List<TagGroupReadWithTags> groups) {
    when(
      () => api.readTagGroupsV1TagsGroupsGet(options: any(named: 'options')),
    ).thenAnswer((_) async => groups);
  }

  /// CUD 메서드는 invalidateSelf로 목록을 갱신하므로, 호출 동안 provider가
  /// autoDispose되지 않게 목록을 구독한 컨테이너를 만든다(=목록 화면이 떠 있는 상황).
  ProviderContainer listeningContainer() {
    final container = makeContainer();
    container.listen(tagGroupsRawProvider, (_, _) {});
    return container;
  }

  group('파생 provider', () {
    test('tagGroupsRaw는 API 응답을 그대로 반환한다', () async {
      final groups = [
        _group('g1', 'A', tags: [_tag('t1', 'g1')]),
      ];
      stubRead(groups);

      final container = makeContainer();
      final result = await container.read(tagGroupsRawProvider.future);

      expect(result, groups);
    });

    test('tagGroups는 TagGroupRead 목록으로 변환한다', () async {
      stubRead([
        _group('g1', 'A', tags: [_tag('t1', 'g1')]),
        _group('g2', 'B'),
      ]);

      final container = makeContainer();
      final result = await container.read(tagGroupsProvider.future);

      expect(result, isA<List<TagGroupRead>>());
      expect(result.map((g) => g.id), ['g1', 'g2']);
    });

    test('tagTree는 태그 개수 내림차순으로 정렬한다', () async {
      stubRead([
        _group('g2', 'B', tags: [_tag('t3', 'g2')]),
        _group('g1', 'A', tags: [_tag('t1', 'g1'), _tag('t2', 'g1')]),
      ]);

      final container = makeContainer();
      final tree = await container.read(tagTreeProvider.future);

      expect(tree.map((g) => g.groupId), ['g1', 'g2']);
      expect(tree.first.tagCount, 2);
    });
  });

  group('TagGroupsRaw - CUD 메서드는 해당 REST API를 호출한다', () {
    test('createGroup', () async {
      stubRead([]);
      when(
        () => api.createTagGroupV1TagsGroupsPost(
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => TagGroupRead(
          id: 'g1',
          name: 'New',
          color: '#000000',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      );

      final container = listeningContainer();
      await container
          .read(tagGroupsRawProvider.notifier)
          .createGroup(TagGroupCreate(name: 'New', color: '#000000'));

      verify(
        () => api.createTagGroupV1TagsGroupsPost(
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('updateGroup', () async {
      stubRead([]);
      when(
        () => api.updateTagGroupV1TagsGroupsGroupIdPatch(
          groupId: any(named: 'groupId'),
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => TagGroupRead(
          id: 'g1',
          name: 'Up',
          color: '#000000',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      );

      final container = listeningContainer();
      await container
          .read(tagGroupsRawProvider.notifier)
          .updateGroup('g1', TagGroupUpdate(name: 'Up'));

      verify(
        () => api.updateTagGroupV1TagsGroupsGroupIdPatch(
          groupId: 'g1',
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('deleteGroup', () async {
      stubRead([]);
      when(
        () => api.deleteTagGroupV1TagsGroupsGroupIdDelete(
          groupId: any(named: 'groupId'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      final container = listeningContainer();
      await container.read(tagGroupsRawProvider.notifier).deleteGroup('g1');

      verify(
        () => api.deleteTagGroupV1TagsGroupsGroupIdDelete(
          groupId: 'g1',
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('createTag', () async {
      stubRead([]);
      when(
        () => api.createTagV1TagsPost(
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => _tag('t1', 'g1'));

      final container = listeningContainer();
      await container
          .read(tagGroupsRawProvider.notifier)
          .createTag(TagCreate(name: 'tag', color: '#FF5733', groupId: 'g1'));

      verify(
        () => api.createTagV1TagsPost(
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('updateTag', () async {
      stubRead([]);
      when(
        () => api.updateTagV1TagsTagIdPatch(
          tagId: any(named: 'tagId'),
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => _tag('t1', 'g1'));

      final container = listeningContainer();
      await container
          .read(tagGroupsRawProvider.notifier)
          .updateTag('t1', TagUpdate(name: 'up'));

      verify(
        () => api.updateTagV1TagsTagIdPatch(
          tagId: 't1',
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('deleteTag', () async {
      stubRead([]);
      when(
        () => api.deleteTagV1TagsTagIdDelete(
          tagId: any(named: 'tagId'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      final container = listeningContainer();
      await container.read(tagGroupsRawProvider.notifier).deleteTag('t1');

      verify(
        () => api.deleteTagV1TagsTagIdDelete(
          tagId: 't1',
          options: any(named: 'options'),
        ),
      ).called(1);
    });
  });

  group('TagGroupsRaw - 캐시 갱신', () {
    test('CUD 후 invalidateSelf로 목록이 재조회된다', () async {
      stubRead([]);
      when(
        () => api.deleteTagV1TagsTagIdDelete(
          tagId: any(named: 'tagId'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      final container = listeningContainer();
      await container.read(tagGroupsRawProvider.future); // 최초 조회
      await container.read(tagGroupsRawProvider.notifier).deleteTag('t1');
      await container.read(tagGroupsRawProvider.future); // 갱신 후 재조회

      verify(
        () => api.readTagGroupsV1TagsGroupsGet(options: any(named: 'options')),
      ).called(2);
    });
  });

  group('Mutation - UI operation state', () {
    test('run 성공 시 상태가 MutationSuccess가 되고 목록이 갱신된다', () async {
      stubRead([]);
      when(
        () => api.deleteTagGroupV1TagsGroupsGroupIdDelete(
          groupId: any(named: 'groupId'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      final container = listeningContainer();
      container.listen(deleteTagGroupMutation, (_, _) {}); // 상태 구독(자동 reset 방지)
      await container.read(tagGroupsRawProvider.future); // 최초 조회

      await deleteTagGroupMutation.run(
        container,
        (tsx) => tsx.get(tagGroupsRawProvider.notifier).deleteGroup('g1'),
      );

      expect(container.read(deleteTagGroupMutation).isSuccess, isTrue);
      verify(
        () => api.deleteTagGroupV1TagsGroupsGroupIdDelete(
          groupId: 'g1',
          options: any(named: 'options'),
        ),
      ).called(1);
      // invalidateSelf로 목록이 재조회됨
      await container.read(tagGroupsRawProvider.future);
      verify(
        () => api.readTagGroupsV1TagsGroupsGet(options: any(named: 'options')),
      ).called(2);
    });

    test('run 실패 시 원래 에러를 rethrow하고 상태가 MutationError가 된다', () async {
      stubRead([]);
      when(
        () => api.deleteTagGroupV1TagsGroupsGroupIdDelete(
          groupId: any(named: 'groupId'),
          options: any(named: 'options'),
        ),
      ).thenThrow(Exception('delete-failed'));

      final container = listeningContainer();
      container.listen(deleteTagGroupMutation, (_, _) {});

      await expectLater(
        deleteTagGroupMutation.run(
          container,
          (tsx) => tsx.get(tagGroupsRawProvider.notifier).deleteGroup('g1'),
        ),
        throwsA(
          predicate((Object? e) => e.toString().contains('delete-failed')),
        ),
      );

      expect(container.read(deleteTagGroupMutation).hasError, isTrue);
    });
  });
}
