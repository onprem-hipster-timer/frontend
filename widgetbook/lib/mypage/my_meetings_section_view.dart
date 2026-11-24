import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError, AsyncLoading, AsyncValue;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/mypage/presentation/widgets/my_meetings_section_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

enum _Load { done, loading, failed }

const _titles = [
  '3월 동아리 정기 모임',
  '졸업 프로젝트 회의',
  '봄 소풍 날짜 정하기',
  '스터디 첫 모임',
  '팀 회식',
  '가족 여행 일정',
  '독서 모임 4월',
  '테니스 레슨 시간',
];

const _modes = [MeetingMode.hourly, MeetingMode.daily, MeetingMode.weekly];

@widgetbook.UseCase(name: '내 모임', type: MyMeetingsSectionView, path: '[마이페이지]')
Widget myMeetingsSectionView(BuildContext context) {
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
  final count = knobs.int.slider(
    label: '만든 모임 수',
    description:
        '$myMeetingsShown개까지 보이고, 넘으면 아래에 모두 보기 (N)이 붙는다. '
        '0이면 아직 만든 모임이 없다고 알린다',
    initialValue: 3,
    max: _titles.length,
  );
  final AsyncValue<List<MeetingRead>> meetings = switch (load) {
    _Load.done => AsyncData([for (var i = 0; i < count; i++) _meeting(i)]),
    _Load.loading => const AsyncLoading(),
    _Load.failed => AsyncError(Exception('불러오기 실패'), StackTrace.empty),
  };
  // 앱에서는 마이페이지 프로필 아래, 좌우 20 여백 안에 놓인다.
  // 모임 만들기·모임 항목·모두 보기를 누르면 그 화면 안내가 뜬다
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: MyMeetingsSectionView(meetings: meetings, onRetry: () {}),
  );
}

/// 새로 만든 순의 [i]번째 모임
MeetingRead _meeting(int i) {
  final start = DateTime(2026, 3, 2 + i * 7);
  final created = DateTime(2026, 2, 27).subtract(Duration(days: i * 2));
  return MeetingRead(
    id: 'sample-$i',
    title: _titles[i],
    startDate: start,
    endDate: start.add(Duration(days: i.isEven ? 4 : 0)),
    excludedDates: const [],
    timezone: 'Asia/Seoul',
    mode: _modes[i % _modes.length],
    startTime: '09:00',
    endTime: '18:00',
    timeSlotMinutes: 30,
    createdAt: created,
    updatedAt: created,
    visibilityLevel: i.isEven
        ? VisibilityLevel.private
        : VisibilityLevel.public,
  );
}
