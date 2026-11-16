import 'dart:async';

import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/providers/auth_selectors.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

final _at = DateTime.utc(2027, 1, 1);

/// 테스트용 미팅. 기본은 2027년 3월 1~5일 6~18시 시간별
MeetingRead makeMeeting({
  String id = 'meeting-1',
  String title = '팀 회의',
  DateTime? startDate,
  DateTime? endDate,
  String timezone = 'Asia/Seoul',
  List<int> availableDays = const [0, 1, 2, 3, 4],
  String startTime = '06:00:00',
  String endTime = '18:00:00',
  int timeSlotMinutes = 30,
  String ownerId = 'owner-1',
}) => MeetingRead(
  id: id,
  ownerId: ownerId,
  title: title,
  startDate: startDate ?? DateTime.utc(2027, 3, 1),
  endDate: endDate ?? DateTime.utc(2027, 3, 5),
  timezone: timezone,
  availableDays: availableDays,
  startTime: startTime,
  endTime: endTime,
  timeSlotMinutes: timeSlotMinutes,
  createdAt: _at,
  updatedAt: _at,
);

/// 받은 요청을 기록하는 [MeetingsClient]
class FakeMeetingsClient extends Fake implements MeetingsClient {
  FakeMeetingsClient({this.meeting, List<String>? calls}) : calls = calls ?? [];

  /// 조회가 돌려주는 미팅. 없으면 만든 미팅을 돌려준다
  MeetingRead? meeting;

  /// 만들기·수정·삭제 요청을 보낸 순서. [FakeVisibilityClient]에 같은 목록을 주면 함께 쌓인다
  final List<String> calls;

  final created = <MeetingCreate>[];
  final deleted = <String>[];
  final reads = <String>[];

  /// 받은 수정 요청 (미팅 id, 본문)
  final updates = <(String, MeetingUpdate)>[];

  /// 설정하면 수정이 이 오류로 실패한다
  Object? updateError;

  /// 설정하면 삭제가 이 오류로 실패한다
  Object? deleteError;

  /// 설정하면 만들기가 이 오류로 실패한다
  Object? createError;

  /// 설정하면 만들기가 이것이 끝날 때까지 기다린다
  Future<void>? createGate;

  /// 설정하면 조회가 이 오류로 실패한다
  Object? readError;

  @override
  Future<MeetingRead> createMeetingV1MeetingsPost({
    required MeetingCreate body,
    String? timezone,
    RequestOptions? options,
  }) async {
    calls.add('create');
    created.add(body);
    await createGate;
    if (createError != null) throw createError!;
    final made = makeMeeting(
      id: 'meeting-new-${created.length}',
      title: body.title,
      startDate: body.startDate,
      endDate: body.endDate,
      timezone: body.timezone,
      availableDays: body.availableDays,
      startTime: body.startTime,
      endTime: body.endTime,
    );
    meeting ??= made;
    return made;
  }

  @override
  Future<MeetingRead> readMeetingV1MeetingsMeetingIdGet({
    required String meetingId,
    String? timezone,
    RequestOptions? options,
  }) async {
    reads.add(meetingId);
    if (readError != null) throw readError!;
    final meeting = this.meeting;
    if (meeting == null) throw StateError('no meeting $meetingId');
    return meeting;
  }

  @override
  Future<MeetingRead> updateMeetingV1MeetingsMeetingIdPatch({
    required String meetingId,
    required MeetingUpdate body,
    String? timezone,
    RequestOptions? options,
  }) async {
    calls.add('update ${body.toJson()}');
    updates.add((meetingId, body));
    if (updateError != null) throw updateError!;
    return makeMeeting(
      id: meetingId,
    ).copyWith(allowGuests: body.allowGuests ?? false);
  }

  @override
  Future<void> deleteMeetingV1MeetingsMeetingIdDelete({
    required String meetingId,
    RequestOptions? options,
  }) async {
    calls.add('delete $meetingId');
    deleted.add(meetingId);
    if (deleteError != null) throw deleteError!;
  }

  /// 가능 시간 조회가 돌려주는 참여자별 가능 시간. 참여·저장하면 backend처럼 바뀐다
  List<AvailabilityRead> availability = [];

  /// 가능 시간 조회 횟수
  var availabilityReads = 0;

  /// 받은 참여 요청의 이름
  final participations = <String>[];

  /// 받은 가능 시간 저장 (참여자 id, 구간)
  final puts = <(String, List<TimeSlotCreate>)>[];

  /// 설정하면 다음 참여 요청 하나가 이 오류로 실패한다
  Object? participateError;

  /// 설정하면 다음 저장 하나가 이 오류로 실패한다
  Object? putError;

  /// 설정하면 가능 시간 조회가 이 오류로 실패한다
  Object? availabilityError;

  /// 설정하면 저장이 이것이 끝날 때까지 기다린다
  Completer<void>? putGate;

  @override
  Future<List<AvailabilityRead>>
  getAvailabilityV1MeetingsMeetingIdAvailabilityGet({
    required String meetingId,
    String? timezone,
    RequestOptions? options,
  }) async {
    availabilityReads++;
    if (availabilityError != null) throw availabilityError!;
    return [...availability];
  }

  /// [userId]로 참여한다. 이미 참여했으면 이름만 바꾼다(backend의 참여 경로와 같다)
  @override
  Future<ParticipantRead> createParticipantV1MeetingsMeetingIdParticipatePost({
    required String meetingId,
    required ParticipantCreate body,
    String? timezone,
    RequestOptions? options,
  }) async {
    participations.add(body.displayName);
    final error = participateError;
    if (error != null) {
      participateError = null;
      throw error;
    }
    final at = availability.indexWhere(
      (entry) => entry.participant.userId == userId,
    );
    if (at >= 0) {
      final renamed = availability[at].participant.copyWith(
        displayName: body.displayName,
      );
      availability[at] = availability[at].copyWith(participant: renamed);
      return renamed;
    }
    final joined = ParticipantRead(
      id: 'participant-$userId',
      meetingId: meetingId,
      displayName: body.displayName,
      createdAt: _at,
      isOwner: meeting?.ownerId == userId,
      userId: userId,
    );
    availability.add(AvailabilityRead(participant: joined, timeSlots: []));
    return joined;
  }

  @override
  Future<List<TimeSlotRead>> setAvailabilityV1MeetingsMeetingIdAvailabilityPut({
    required String meetingId,
    required String participantId,
    required List<TimeSlotCreate> body,
    String? timezone,
    RequestOptions? options,
  }) async {
    puts.add((participantId, body));
    await putGate?.future;
    final error = putError;
    if (error != null) {
      putError = null;
      throw error;
    }
    final slots = [
      for (final (i, slot) in body.indexed)
        TimeSlotRead(
          id: 'slot-$i',
          participantId: participantId,
          startTime: slot.startTime,
          endTime: slot.endTime,
        ),
    ];
    final at = availability.indexWhere(
      (entry) => entry.participant.id == participantId,
    );
    availability[at] = availability[at].copyWith(timeSlots: slots);
    return slots;
  }

  /// 참여 요청을 보내는 로그인 사용자([meetingOverrides]의 사용자)
  String userId = 'user-1';
}

/// 참여자 [id]의 가능 시간. [slots]는 UTC 구간. [owner]는 주인, [guest]는 게스트 참여자(회원 id 없음)
AvailabilityRead availabilityOf(
  String id, {
  String? name,
  String? userId,
  bool owner = false,
  bool guest = false,
  List<(DateTime, DateTime)> slots = const [],
}) => AvailabilityRead(
  participant: ParticipantRead(
    id: id,
    meetingId: 'meeting-1',
    displayName: name ?? id,
    createdAt: _at,
    isOwner: owner,
    isGuest: guest,
    userId: guest ? null : userId ?? 'user-of-$id',
  ),
  timeSlots: [
    for (final (i, (start, end)) in slots.indexed)
      TimeSlotRead(
        id: '$id-slot-$i',
        participantId: id,
        startTime: start,
        endTime: end,
      ),
  ],
);

/// 받은 공개 범위 요청을 기록하는 [VisibilityClient]
class FakeVisibilityClient extends Fake implements VisibilityClient {
  FakeVisibilityClient({List<String>? calls}) : calls = calls ?? [];

  /// 공개 범위 요청을 보낸 순서. [FakeMeetingsClient]와 같은 목록을 쓸 수 있다
  final List<String> calls;

  final updates = <(ResourceType, String, VisibilityUpdate)>[];

  /// 설정하면 공개 범위 저장이 이 오류로 실패한다
  Object? setError;

  @override
  Future<VisibilityRead> setVisibilityV1VisibilityResourceTypeResourceIdPut({
    required ResourceType resourceType,
    required String resourceId,
    required VisibilityUpdate body,
    RequestOptions? options,
  }) async {
    calls.add('visibility ${body.level.name}');
    if (setError != null) throw setError!;
    updates.add((resourceType, resourceId, body));
    return VisibilityRead(
      id: 'visibility-${updates.length}',
      resourceType: resourceType,
      resourceId: resourceId,
      ownerId: 'owner-1',
      level: body.level,
      createdAt: _at,
      updatedAt: _at,
    );
  }
}

/// 정한 값을 돌려주는 앱 시간대
class FixedTimezone extends TimezoneNotifier {
  FixedTimezone(this.value);

  final String value;

  @override
  Future<String> build() async => value;
}

/// 모임 화면을 띄울 때 바꿔 끼우는 것. 로그인한 사람의 이름은 [name]
List<Override> meetingOverrides({
  required FakeMeetingsClient meetings,
  FakeVisibilityClient? visibility,
  String? name = '지현',
  String timezone = 'Asia/Seoul',
}) => [
  meetingsApiProvider.overrideWithValue(meetings),
  visibilityApiProvider.overrideWithValue(visibility ?? FakeVisibilityClient()),
  timezoneProvider.overrideWith(() => FixedTimezone(timezone)),
  appOriginProvider.overrideWithValue('https://app.example.com'),
  currentUserProvider.overrideWithValue(
    AuthUser(
      id: 'user-1',
      email: 'user@example.com',
      emailVerified: true,
      createdAt: _at,
      name: name,
    ),
  ),
];
