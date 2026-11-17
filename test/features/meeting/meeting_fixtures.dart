import 'dart:async';

import 'package:dio/dio.dart'
    show DioException, DioExceptionType, RequestOptions, Response;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/auth/guest_user.dart';
import 'package:momeet/core/providers/auth_selectors.dart';
import 'package:momeet/core/providers/auth_status.dart';
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
  List<DateTime> excludedDates = const [],
  String timezone = 'Asia/Seoul',
  MeetingMode mode = MeetingMode.hourly,
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
  excludedDates: excludedDates,
  timezone: timezone,
  mode: mode,
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

  /// 응답 상태로 거절할 때 먼저 부른다. 앱의 요청 파이프라인(AuthInterceptor)이 거절을 인증 상태에 적는 것을
  /// 대신한다. 화면 테스트가 `authProvider.notifier.guestRefused`를 넣는다
  Future<void> Function(int status)? onRefused;

  /// [error]를 던진다. 응답 상태가 있으면 그 전에 [onRefused]에 알린다
  Future<Never> _raise(Object error) async {
    final status = error is DioException ? error.response?.statusCode : null;
    final refused = onRefused;
    if (status != null && refused != null) await refused(status);
    throw error;
  }

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
      excludedDates: body.excludedDates,
      timezone: body.timezone,
      mode: body.mode,
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
    if (readError != null) await _raise(readError!);
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
    final stored = meeting;
    if (stored == null || stored.id != meetingId) {
      return makeMeeting(
        id: meetingId,
      ).copyWith(allowGuests: body.allowGuests ?? false);
    }
    // 조회하는 미팅이면 backend처럼 보낸 칸만 바꿔 둔다
    return meeting = stored.copyWith(
      title: body.title ?? stored.title,
      startDate: body.startDate ?? stored.startDate,
      endDate: body.endDate ?? stored.endDate,
      excludedDates: body.excludedDates ?? stored.excludedDates,
      mode: body.mode ?? stored.mode,
      startTime: body.startTime ?? stored.startTime,
      endTime: body.endTime ?? stored.endTime,
      allowGuests: body.allowGuests ?? stored.allowGuests,
    );
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
    if (availabilityError != null) await _raise(availabilityError!);
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
      await _raise(error);
    }
    if (guestName case final guest?) return _joinAsGuest(meetingId, guest);
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
      await _raise(error);
    }
    final slots = [
      for (final (i, slot) in body.indexed)
        TimeSlotRead(
          id: 'slot-$i',
          participantId: participantId,
          startTime: slot.startTime,
          endTime: slot.endTime,
          kind: slot.kind,
        ),
    ];
    final at = availability.indexWhere(
      (entry) => entry.participant.id == participantId,
    );
    availability[at] = availability[at].copyWith(timeSlots: slots);
    return slots;
  }

  /// 결과 조회가 돌려주는 칸. 참여자 수는 [availability]의 수다
  List<AvailabilityCell> resultGrid = [];

  /// 결과 조회 횟수
  var resultReads = 0;

  /// 설정하면 결과 조회가 이 오류로 실패한다
  Object? resultError;

  /// 로그인하지 않은 방문자처럼 주인 id 없는 미팅과 사람 수만 돌려준다. 미팅이 없으면 404다
  @override
  Future<MeetingResultRead> getMeetingResultV1MeetingsMeetingIdResultGet({
    required String meetingId,
    String? timezone,
    RequestOptions? options,
  }) async {
    resultReads++;
    if (resultError != null) throw resultError!;
    final meeting = this.meeting;
    if (meeting == null) throw notFound();
    return MeetingResultRead(
      meeting: meeting.copyWith(ownerId: null),
      participantCount: availability.length,
      availabilityGrid: resultGrid,
    );
  }

  /// 받은 참여자 빼기의 참여자 id
  final removedParticipants = <String>[];

  /// 설정하면 참여자 빼기가 이 오류로 실패한다
  Object? removeError;

  /// 설정하면 참여자 빼기가 이것이 끝날 때까지 기다린다
  Completer<void>? removeGate;

  /// 참여자와 그 가능 시간을 지운다(backend의 참여자 빼기와 같다)
  @override
  Future<void>
  removeParticipantV1MeetingsMeetingIdParticipantsParticipantIdDelete({
    required String meetingId,
    required String participantId,
    RequestOptions? options,
  }) async {
    removedParticipants.add(participantId);
    await removeGate?.future;
    if (removeError != null) throw removeError!;
    availability.removeWhere((entry) => entry.participant.id == participantId);
  }

  /// 참여 요청을 보내는 로그인 사용자([meetingOverrides]의 사용자)
  String userId = 'user-1';

  /// 주면 참여 요청을 이 이름의 게스트가 보낸다(backend처럼 보낸 이름이 아니라 게스트 이름으로 참여한다)
  String? guestName;

  /// 게스트 [name]의 참여자. 이미 있으면 그대로 돌려준다
  ParticipantRead _joinAsGuest(String meetingId, String name) {
    for (final entry in availability) {
      final participant = entry.participant;
      if (participant.isGuest && participant.displayName == name) {
        return participant;
      }
    }
    final joined = ParticipantRead(
      id: 'participant-guest',
      meetingId: meetingId,
      displayName: name,
      createdAt: _at,
      isOwner: false,
      isGuest: true,
    );
    availability.add(AvailabilityRead(participant: joined, timeSlots: []));
    return joined;
  }
}

/// backend가 404로 답한 요청의 오류
DioException notFound([String errorType = 'MeetingNotFoundError']) {
  final request = RequestOptions(path: '/v1/meetings');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: request,
      statusCode: 404,
      data: {'error_type': errorType, 'message': 'not found'},
    ),
  );
}

/// 참여자 [id]의 가능 시간. [slots]는 되는, [unavailable]은 안 되는 UTC 구간. [owner]는 주인, [guest]는 게스트
/// 참여자(회원 id 없음)
AvailabilityRead availabilityOf(
  String id, {
  String? name,
  String? userId,
  bool owner = false,
  bool guest = false,
  List<(DateTime, DateTime)> slots = const [],
  List<(DateTime, DateTime)> unavailable = const [],
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
        kind: TimeSlotKind.available,
      ),
    for (final (i, (start, end)) in unavailable.indexed)
      TimeSlotRead(
        id: '$id-unavailable-$i',
        participantId: id,
        startTime: start,
        endTime: end,
        kind: TimeSlotKind.unavailable,
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

  /// 조회가 돌려주는 공개 범위. 없으면 404다(정한 적이 없다). 저장하면 backend처럼 바뀐다
  VisibilityRead? current;

  /// 설정하면 공개 범위 조회가 이 오류로 실패한다
  Object? getError;

  /// 공개 범위 조회 횟수
  var reads = 0;

  @override
  Future<VisibilityRead> getVisibilityV1VisibilityResourceTypeResourceIdGet({
    required ResourceType resourceType,
    required String resourceId,
    RequestOptions? options,
  }) async {
    reads++;
    if (getError != null) throw getError!;
    return current ?? (throw notFound('VisibilityNotFoundError'));
  }

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
    return current = visibilityOf(
      body.level,
      resourceId: resourceId,
      emails: body.allowedEmails ?? current?.allowedEmails ?? const [],
      domains: body.allowedDomains ?? current?.allowedDomains ?? const [],
    );
  }
}

/// 미팅 [resourceId]의 공개 범위 [level]
VisibilityRead visibilityOf(
  VisibilityLevel level, {
  String resourceId = 'meeting-1',
  List<String> emails = const [],
  List<String> domains = const [],
}) => VisibilityRead(
  id: 'visibility-$resourceId',
  resourceType: ResourceType.meeting,
  resourceId: resourceId,
  ownerId: 'owner-1',
  level: level,
  createdAt: _at,
  updatedAt: _at,
  allowedEmails: emails,
  allowedDomains: domains,
);

/// 정한 값을 돌려주는 앱 시간대
class FixedTimezone extends TimezoneNotifier {
  FixedTimezone(this.value);

  final String value;

  @override
  Future<String> build() async => value;
}

/// 로그인한 사람(user-1). 이름은 [name]
AuthUser meetingUser({String? name = '지현'}) => AuthUser(
  id: 'user-1',
  email: 'user@example.com',
  emailVerified: true,
  createdAt: _at,
  name: name,
);

/// 모임 화면을 띄울 때 바꿔 끼우는 것. 로그인한 사람의 이름은 [name]이고, [signedIn]이 false면 로그인하지
/// 않은 방문자다. [session]을 주면 그 값이 바뀔 때 로그인 상태가 바뀐다(세션이 끝나는 경우). [guest]를 주면
/// 회원 대신 그 게스트이고, [guestDenial]은 요청 파이프라인이 그 게스트 상태에 적은 거절 까닭이다
List<Override> meetingOverrides({
  required FakeMeetingsClient meetings,
  FakeVisibilityClient? visibility,
  String? name = '지현',
  bool signedIn = true,
  ValueNotifier<AuthUser?>? session,
  GuestUser? guest,
  GuestDenial? guestDenial,
  String timezone = 'Asia/Seoul',
}) => [
  meetingsApiProvider.overrideWithValue(meetings),
  currentGuestProvider.overrideWithValue(guest),
  currentGuestDenialProvider.overrideWithValue(guestDenial),
  visibilityApiProvider.overrideWithValue(visibility ?? FakeVisibilityClient()),
  timezoneProvider.overrideWith(() => FixedTimezone(timezone)),
  appOriginProvider.overrideWithValue('https://app.example.com'),
  if (session != null)
    currentUserProvider.overrideWith((ref) {
      void changed() => ref.invalidateSelf();
      session.addListener(changed);
      ref.onDispose(() => session.removeListener(changed));
      return session.value;
    })
  else
    currentUserProvider.overrideWithValue(
      signedIn && guest == null ? meetingUser(name: name) : null,
    ),
];
