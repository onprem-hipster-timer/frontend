import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError, AsyncLoading, AsyncValue;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/mypage/domain/my_page_models.dart';
import 'package:momeet/features/mypage/presentation/widgets/activity_stats_section_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

enum _Load { done, loading, failed }

@widgetbook.UseCase(
  name: '활동 요약',
  type: ActivityStatsSectionView,
  path: '[마이페이지]',
)
Widget activityStatsSectionView(BuildContext context) {
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
  int count(String label, int initialValue) => knobs.int.slider(
    label: label,
    initialValue: initialValue,
    max: 1200,
    description: '전체는 미지정·예정·완료를 더한 수. 모두 0이면 처음 쓰는 사람의 모습이다',
  );
  final unscheduled = count('미지정', 4);
  final scheduled = count('예정', 7);
  final done = count('완료', 12);
  final AsyncValue<TodoStatistics> stats = switch (load) {
    _Load.done => AsyncData(
      TodoStatistics(
        totalCount: unscheduled + scheduled + done,
        unscheduledCount: unscheduled,
        scheduledCount: scheduled,
        doneCount: done,
        cancelledCount: 0,
      ),
    ),
    _Load.loading => const AsyncLoading(),
    _Load.failed => AsyncError(Exception('불러오기 실패'), StackTrace.empty),
  };
  // 앱에서는 마이페이지 가운데, 좌우 20 여백 안에 놓인다
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: ActivityStatsSectionView(stats: stats, onRetry: () {}),
  );
}
