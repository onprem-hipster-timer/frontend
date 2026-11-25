import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/shared/api/rest/export.dart';

TagRead _tag(String id, String name, String color, DateTime now) => TagRead(
  id: id,
  name: name,
  color: color,
  groupId: 'trial-tag-group',
  createdAt: now,
  updatedAt: now,
);

DateTime _at(DateTime day, int hour) =>
    DateTime(day.year, day.month, day.day, hour);

/// [now]에 시작하는 체험: 일주일 뒤 오전의 시험(확정)과 같은 달 저녁의 약속(계획됨)이 든 달력([trialDays])
TrialFlow trialStart(DateTime now) {
  final days = trialDays(DateTime(now.year, now.month, now.day));
  final exam = days.exam;
  final dinner = days.dinner;
  return TrialFlow(
    now: now,
    exam: ScheduleRead(
      id: 'trial-exam',
      title: trialExamTitle,
      startTime: _at(exam, 9),
      endTime: _at(exam, 12),
      state: ScheduleState.confirmed,
      createdAt: now,
      description: trialExamDescription,
      tags: [_tag('trial-tag-study', trialExamTag, '#2E7D32', now)],
    ),
    dinner: ScheduleRead(
      id: 'trial-dinner',
      title: trialDinnerTitle,
      startTime: _at(dinner, 19),
      endTime: _at(dinner, 21),
      state: ScheduleState.planned,
      createdAt: now,
      description: trialDinnerDescription,
      tags: [_tag('trial-tag-friend', trialDinnerTag, '#8E24AA', now)],
    ),
  );
}
