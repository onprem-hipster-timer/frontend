import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError, AsyncLoading, AsyncValue;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/mypage/domain/my_page_models.dart';
import 'package:momeet/features/mypage/presentation/widgets/tag_stats_section_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

enum _Load { done, loading, failed }

const _tagNames = [
  '운동',
  '영어 공부',
  '회의',
  '독서',
  '동아리',
  '장보기',
  '사이드 프로젝트',
  '병원',
  '여행',
  '가족',
];

@widgetbook.UseCase(name: '사용한 태그', type: TagStatsSectionView, path: '[마이페이지]')
Widget tagStatsSectionView(BuildContext context) {
  final knobs = context.knobs;
  final load = knobs.object.dropdown(
    label: '상태',
    options: _Load.values,
    labelBuilder: (load) => switch (load) {
      _Load.done => '불러옴',
      _Load.loading => '불러오는 중',
      _Load.failed => '불러올 수 없음',
    },
  );
  final tagCount = knobs.int.slider(
    label: '쓴 태그 수',
    description: '많이 쓴 순으로 8개까지 보인다. 0이면 아직 태그를 사용하지 않았다고 알린다',
    initialValue: 6,
    max: _tagNames.length,
  );
  final firstName = knobs.string(
    label: '가장 많이 쓴 태그 이름',
    description: '길면 칩이 줄 폭을 넘지 않게 한 줄로 줄인다',
    initialValue: _tagNames.first,
  );
  final AsyncValue<TagUsageStatistics> tagStats = switch (load) {
    _Load.done => AsyncData(
      TagUsageStatistics(
        tagUsageMap: {
          for (var i = 0; i < tagCount; i++)
            'tag-$i': TagUsageItem(
              tagId: 'tag-$i',
              tagName: i == 0 ? firstName : _tagNames[i],
              count: 31 - i * 3,
            ),
        },
      ),
    ),
    _Load.loading => const AsyncLoading(),
    _Load.failed => AsyncError(Exception('불러오기 실패'), StackTrace.empty),
  };
  // 앱에서는 마이페이지 아래쪽, 좌우 20 여백 안에 놓인다
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: TagStatsSectionView(tagStats: tagStats, onRetry: () {}),
  );
}
