// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/availability_read.dart';
import '../models/guest_import.dart';
import '../models/meeting_create.dart';
import '../models/meeting_read.dart';
import '../models/meeting_result_read.dart';
import '../models/meeting_update.dart';
import '../models/participant_create.dart';
import '../models/participant_read.dart';
import '../models/time_slot_create.dart';
import '../models/time_slot_read.dart';

part 'meetings_client.g.dart';

@RestApi()
abstract class MeetingsClient {
  factory MeetingsClient(Dio dio, {String? baseUrl}) = _MeetingsClient;

  /// Create Meeting.
  ///
  /// 일정 조율 생성.
  ///
  /// 인증 필수: 일정 조율 생성자는 소유자가 됩니다.
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @POST('/v1/meetings')
  Future<MeetingRead> createMeetingV1MeetingsPost({
    @Body() required MeetingCreate body,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });

  /// Read Meetings.
  ///
  /// 내가 생성한 일정 조율 목록 조회.
  ///
  /// 인증 필수: 본인이 생성한 일정 조율만 조회됩니다.
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/meetings')
  Future<List<MeetingRead>> readMeetingsV1MeetingsGet({
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });

  /// Update Meeting.
  ///
  /// 일정 조율 수정.
  ///
  /// 인증 필수: 소유자만 수정 가능합니다.
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @PATCH('/v1/meetings/{meeting_id}')
  Future<MeetingRead> updateMeetingV1MeetingsMeetingIdPatch({
    @Path('meeting_id') required String meetingId,
    @Body() required MeetingUpdate body,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });

  /// Delete Meeting.
  ///
  /// 일정 조율 삭제.
  ///
  /// 인증 필수: 소유자만 삭제 가능합니다. 삭제를 커밋한 뒤 그 미팅의 게스트를 모두 폐기합니다.
  @DELETE('/v1/meetings/{meeting_id}')
  Future<void> deleteMeetingV1MeetingsMeetingIdDelete({
    @Path('meeting_id') required String meetingId,
    @DioOptions() RequestOptions? options,
  });

  /// Read Meeting.
  ///
  /// 일정 조율 상세 조회.
  ///
  /// 인증 선택적: 회원은 접근 권한이 있으면, 그 미팅의 게스트와 로그인하지 않은 방문자는 PUBLIC이면 조회할 수 있습니다.
  /// 게스트와 방문자의 응답에는 owner_id가 없습니다(null).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/meetings/{meeting_id}')
  Future<MeetingRead> readMeetingV1MeetingsMeetingIdGet({
    @Path('meeting_id') required String meetingId,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });

  /// Remove Participant.
  ///
  /// 참여자 빼기.
  ///
  /// 인증 필수: 소유자만 뺄 수 있습니다(자기 참여자 포함). 다른 회원에게는 없는 미팅과 같은 404입니다.
  /// 참여자와 그 가능 시간이 지워집니다. 게스트 참여자는 그 게스트를 폐기합니다(게스트 자기 삭제와 같다).
  @DELETE('/v1/meetings/{meeting_id}/participants/{participant_id}')
  Future<void>
  removeParticipantV1MeetingsMeetingIdParticipantsParticipantIdDelete({
    @Path('meeting_id') required String meetingId,
    @Path('participant_id') required String participantId,
    @DioOptions() RequestOptions? options,
  });

  /// Import Guest.
  ///
  /// 게스트 가져오기.
  ///
  /// 인증 필수: 회원만. 본문의 guest_token은 이 미팅 게스트의 JWT로, 그 게스트를 쥐고 있다는 증명입니다.
  /// 게스트 참여자의 가능 시간을 회원의 참여자에 합치고(없으면 프로필 표시 이름으로 만든다) 게스트를 폐기합니다.
  /// DB 변경은 한 트랜잭션이고, 게스트의 Kratos identity는 커밋한 뒤 지웁니다.
  /// 회원이 접근할 수 없는 미팅은 404 MeetingNotFoundError, 게스트 토큰이 아니거나 검증에 실패하면 422,.
  /// 게스트가 없거나(가져온 뒤 다시 부른 경우 포함) 다른 미팅의 게스트면 404 GuestNotFoundError,.
  /// 같은 참여자를 쓰는 다른 요청과 겹치면 409이고 아무것도 바뀌지 않습니다. GUEST_ENABLED가 꺼져 있으면 404.
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @POST('/v1/meetings/{meeting_id}/guest-import')
  Future<AvailabilityRead> importGuestV1MeetingsMeetingIdGuestImportPost({
    @Path('meeting_id') required String meetingId,
    @Body() required GuestImport body,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });

  /// Create Participant.
  ///
  /// 참여자 등록.
  ///
  /// 인증 필수: 접근 권한이 있는 회원과 그 미팅의 게스트가 참여할 수 있습니다.
  /// 미팅마다 회원당·게스트당 참여자는 한 명입니다. 처음 등록하면 201, 이미 참여했으면 기존 참여자를 200으로 반환합니다.
  /// 회원은 다시 등록하면 표시 이름을 보낸 값으로 바꿉니다. 게스트 참여자의 표시 이름은 보낸 값과 상관없이 게스트 이름입니다.
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @POST('/v1/meetings/{meeting_id}/participate')
  Future<ParticipantRead> createParticipantV1MeetingsMeetingIdParticipatePost({
    @Path('meeting_id') required String meetingId,
    @Body() required ParticipantCreate body,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });

  /// Set Availability.
  ///
  /// 참여자의 가능 시간 설정.
  ///
  /// 인증 필수: 회원과 그 미팅의 게스트가 본인의 참여 시간만 설정 가능합니다.
  /// 기존 시간 슬롯을 모두 삭제하고 새로운 시간 슬롯을 설정합니다.
  /// 슬롯은 반열린 구간 [start_time, end_time)이고 시간대가 없는 값은 UTC로 읽습니다. 보낸 구간 그대로 저장합니다.
  /// 슬롯 수는 미팅의 칸 수까지입니다 (넘으면 422). 슬롯이 미팅의 날짜·시간 범위나 칸에 맞는지는 검사하지 않습니다.
  /// 슬롯마다 kind(available, unavailable, 기본 available)가 있고, available 슬롯과 unavailable 슬롯이 겹치면 422입니다(맞닿는 것은 됩니다).
  ///
  /// :param meeting_id: 일정 조율 ID.
  /// :param participant_id: 참여자 ID (쿼리 파라미터).
  /// :param time_slots: 시간 슬롯 리스트 (요청 본문).
  ///
  /// [participantId] - 참여자 ID.
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @PUT('/v1/meetings/{meeting_id}/availability')
  Future<List<TimeSlotRead>> setAvailabilityV1MeetingsMeetingIdAvailabilityPut({
    @Path('meeting_id') required String meetingId,
    @Query('participant_id') required String participantId,
    @Body() required List<TimeSlotCreate> body,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });

  /// Get Availability.
  ///
  /// 전체 참여자의 가능 시간 조회.
  ///
  /// 인증 필수: 접근 권한이 있는 회원과 그 미팅의 게스트가 조회할 수 있습니다. 게스트의 응답에는 참여자의 user_id가 없습니다(null).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/meetings/{meeting_id}/availability')
  Future<List<AvailabilityRead>>
  getAvailabilityV1MeetingsMeetingIdAvailabilityGet({
    @Path('meeting_id') required String meetingId,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });

  /// Get Meeting Result.
  ///
  /// 공통 가능 시간 분석 결과 조회.
  ///
  /// 인증 선택적: 회원은 접근 권한이 있으면, 그 미팅의 게스트와 로그인하지 않은 방문자는 PUBLIC이면 조회할 수 있습니다.
  /// 미팅의 시간대에서 미팅 날짜(제외 날짜를 뺀 기간)·하루 범위·시간 단위로 만든 칸마다, 그 칸을 모두 덮는.
  /// available 구간을 가진 참여자 수(count)와 unavailable 구간을 가진 참여자 수(unavailable_count)를 셉니다.
  /// 게스트와 방문자의 응답에는 owner_id가 없습니다(null).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/meetings/{meeting_id}/result')
  Future<MeetingResultRead> getMeetingResultV1MeetingsMeetingIdResultGet({
    @Path('meeting_id') required String meetingId,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });
}
