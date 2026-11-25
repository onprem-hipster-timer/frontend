import 'package:momeet/features/meeting/meeting.dart' show MeetingBoard;
import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:timezone/timezone.dart' as tz;

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

/// [now]에 시작하는 체험: 일주일 뒤 오전의 시험과 같은 달 저녁의 약속이 든 달력([trialDays]). 앱이 새 일정에
/// 주는 상태처럼 둘 다 계획됨이다
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
      state: ScheduleState.planned,
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

/// 견본 모임의 시간대. 칸의 시각은 이 시간대의 벽시계 시각이다
const _meetingTimezone = 'Asia/Seoul';

/// 견본 모임을 보는 나(모임을 만든 사람)의 계정 이메일
const trialMeetingEmail = 'jiwoo@example.com';

/// 견본 모임에 시간을 넣은 사람: 약속 날에서 며칠 떨어진 날(-2~2)과 그날의 시각 구간(시), 그리고 안 되는 날.
/// 맨 앞이 나다
const _meetingPeople =
    <
      ({
        String name,
        bool guest,
        List<(int, double, double)> available,
        List<int> busy,
      })
    >[
      (
        name: '지우',
        guest: false,
        available: [(-1, 19, 21), (0, 18, 21), (2, 19, 22)],
        busy: [],
      ),
      (
        name: '길동',
        guest: false,
        available: [(0, 19, 21), (1, 18, 21)],
        busy: [-1],
      ),
      (
        name: '서연',
        guest: true,
        available: [(-2, 18, 20), (0, 19, 22), (2, 20, 22)],
        busy: [],
      ),
      (
        name: '준호',
        guest: false,
        available: [(-1, 19, 21), (0, 19, 21), (1, 19, 21)],
        busy: [],
      ),
    ];

/// [flow]의 약속([TrialFlow.dinner])으로 내가 만든 모임에 나를 포함한 넷이 시간을 넣은 모임 화면의 값. 약속 날
/// 앞뒤 이틀씩 닷새, 저녁 6시~10시의 시간별 모임이고, 넷 모두 되는 시간은 약속 날 저녁 7시~9시다.
/// 시간대 DB가 불러와져 있어야 한다
MeetingBoard trialMeeting(TrialFlow flow) {
  final now = flow.now;
  final dinner = flow.dinner.startTime;
  final location = tz.getLocation(_meetingTimezone);
  DateTime day(int offset) =>
      DateTime.utc(dinner.year, dinner.month, dinner.day + offset);
  DateTime at(int offset, double hour) => tz.TZDateTime(
    location,
    dinner.year,
    dinner.month,
    dinner.day + offset,
    0,
    (hour * 60).round(),
  ).toUtc();
  final meeting = MeetingRead(
    id: 'trial-meeting',
    title: flow.dinner.title,
    startDate: day(-2),
    endDate: day(2),
    excludedDates: const [],
    timezone: _meetingTimezone,
    mode: MeetingMode.hourly,
    startTime: '18:00:00',
    endTime: '22:00:00',
    timeSlotMinutes: 30,
    createdAt: now,
    updatedAt: now,
    ownerId: 'trial-user',
    allowGuests: true,
    visibilityLevel: VisibilityLevel.public,
  );
  return MeetingBoard(
    meeting: meeting,
    availability: [
      for (final (i, person) in _meetingPeople.indexed)
        AvailabilityRead(
          participant: ParticipantRead(
            id: 'trial-participant-$i',
            meetingId: meeting.id,
            displayName: person.name,
            createdAt: now,
            isOwner: i == 0,
            isGuest: person.guest,
            userId: person.guest
                ? null
                : (i == 0 ? 'trial-user' : 'trial-user-$i'),
          ),
          timeSlots: [
            for (final (j, (offset, from, to)) in person.available.indexed)
              TimeSlotRead(
                id: 'trial-slot-$i-$j',
                participantId: 'trial-participant-$i',
                startTime: at(offset, from),
                endTime: at(offset, to),
                kind: TimeSlotKind.available,
              ),
            for (final offset in person.busy)
              TimeSlotRead(
                id: 'trial-slot-$i-busy-$offset',
                participantId: 'trial-participant-$i',
                startTime: at(offset, 18),
                endTime: at(offset, 22),
                kind: TimeSlotKind.unavailable,
              ),
          ],
        ),
    ],
    userId: 'trial-user',
    selfName: _meetingPeople.first.name,
  );
}
