import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_adjustment_notice.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_a.dart';

@widgetbook.UseCase(
  name: '저절로 맞춘 것 알림',
  type: MeetingAdjustmentNotice,
  path: '[모임]/모임 만들기',
)
Widget meetingAdjustmentNotice(BuildContext context) {
  final adjusted = context.knobs.iterable.segmented(
    label: '맞춘 것',
    description: '앞의 답을 바꿔 뒤의 답을 묻지 않고 맞췄을 때 지금 질문 위에 뜬다. 여러 개면 줄마다 하나씩',
    options: MeetingAdjustment.values,
    initialOption: const [MeetingAdjustment.weeklyPeriod],
    labelBuilder: _nameOf,
  );
  final weekly =
      adjusted.contains(MeetingAdjustment.weeklyPeriod) ||
      adjusted.contains(MeetingAdjustment.weeklyExclusionsDropped);
  // 문구에 드는 기간: 요일별은 7일, 시간별로 줄였으면 5일, 그 밖에는 2주
  final dates = weekly
      ? MeetingDates.period(meetingSampleDay(8), 7)
      : adjusted.contains(MeetingAdjustment.hourlyTrimmed)
      ? MeetingDates.period(meetingSampleDay(8), 5)
      : MeetingDates.range(meetingSampleDay(8), meetingSampleDay(19));
  final draft = MeetingDraft(
    mode: weekly ? MeetingMode.weekly : MeetingMode.daily,
    dates: dates,
  );
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: adjusted.isEmpty
        ? const SizedBox.shrink()
        : MeetingAdjustmentNotice(adjusted: adjusted.toSet(), draft: draft),
  );
}

String _nameOf(MeetingAdjustment adjustment) => switch (adjustment) {
  MeetingAdjustment.exclusionsDropped => '기간 밖 제외 날짜 뺌',
  MeetingAdjustment.weeklyPeriod => '요일별 7일로 맞춤',
  MeetingAdjustment.weeklyExclusionsDropped => '요일별이라 제외 되돌림',
  MeetingAdjustment.weeklyRestored => '요일별 전 기간으로 되돌림',
  MeetingAdjustment.hourlyTrimmed => '시간별 5일로 줄임',
  MeetingAdjustment.hourlyToDaily => '시간별을 날짜별로',
  MeetingAdjustment.weeklyToDaily => '요일별을 날짜별로',
  MeetingAdjustment.guestsDropped => '비공개라 게스트 지움',
  MeetingAdjustment.accessDropped => '공개라 참여할 사람 지움',
};
