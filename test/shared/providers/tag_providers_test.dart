import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/providers/tag_providers.dart';

class MockTagsClient extends Mock implements TagsClient {}

class FakeTagGroupCreate extends Fake implements TagGroupCreate {}

class FakeTagCreate extends Fake implements TagCreate {}

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
    registerFallbackValue(FakeTagCreate());
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

  group('TagMutations - 태그 그룹 CRUD', () {
    test('createGroup은 API를 호출하고 결과를 반환한다', () async {
      stubRead([]);
      final created = TagGroupRead(
        id: 'g1',
        name: 'New',
        color: '#000000',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      when(
        () => api.createTagGroupV1TagsGroupsPost(
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => created);

      final container = makeContainer();
      final result = await container
          .read(tagMutationsProvider.notifier)
          .createGroup(TagGroupCreate(name: 'New', color: '#000000'));

      expect(result, created);
      verify(
        () => api.createTagGroupV1TagsGroupsPost(
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('deleteGroup은 API를 호출한다', () async {
      stubRead([]);
      when(
        () => api.deleteTagGroupV1TagsGroupsGroupIdDelete(
          groupId: any(named: 'groupId'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      await container.read(tagMutationsProvider.notifier).deleteGroup('g1');

      verify(
        () => api.deleteTagGroupV1TagsGroupsGroupIdDelete(
          groupId: 'g1',
          options: any(named: 'options'),
        ),
      ).called(1);
    });
  });

  group('TagMutations - 태그 CRUD', () {
    test('createTag은 API를 호출한다', () async {
      stubRead([]);
      final created = _tag('t1', 'g1');
      when(
        () => api.createTagV1TagsPost(
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => created);

      final container = makeContainer();
      final result = await container
          .read(tagMutationsProvider.notifier)
          .createTag(TagCreate(name: 'tag', color: '#FF5733', groupId: 'g1'));

      expect(result, created);
      verify(
        () => api.createTagV1TagsPost(
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('deleteTag은 API를 호출한다', () async {
      stubRead([]);
      when(
        () => api.deleteTagV1TagsTagIdDelete(
          tagId: any(named: 'tagId'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      await container.read(tagMutationsProvider.notifier).deleteTag('t1');

      verify(
        () => api.deleteTagV1TagsTagIdDelete(
          tagId: 't1',
          options: any(named: 'options'),
        ),
      ).called(1);
    });
  });

  group('TagMutations - 캐시 무효화', () {
    test('mutation 후 tagGroupsRaw가 재조회된다', () async {
      stubRead([]);
      when(
        () => api.deleteTagV1TagsTagIdDelete(
          tagId: any(named: 'tagId'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      // keepAlive: 무효화 후 재계산을 관찰하기 위해 구독 유지
      container.listen(tagGroupsRawProvider, (_, _) {});

      await container.read(tagGroupsRawProvider.future);
      await container.read(tagMutationsProvider.notifier).deleteTag('t1');
      await container.read(tagGroupsRawProvider.future);

      verify(
        () => api.readTagGroupsV1TagsGroupsGet(options: any(named: 'options')),
      ).called(2);
    });
  });
}
