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
}) => MeetingRead(
  id: id,
  ownerId: 'owner-1',
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
  FakeMeetingsClient({this.meeting});

  /// 조회가 돌려주는 미팅. 없으면 만든 미팅을 돌려준다
  MeetingRead? meeting;

  final created = <MeetingCreate>[];
  final deleted = <String>[];
  final reads = <String>[];

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
  Future<void> deleteMeetingV1MeetingsMeetingIdDelete({
    required String meetingId,
    RequestOptions? options,
  }) async {
    deleted.add(meetingId);
  }
}

/// 받은 공개 범위 요청을 기록하는 [VisibilityClient]
class FakeVisibilityClient extends Fake implements VisibilityClient {
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
