// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/availability_read.dart';
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

  /// Read Meeting.
  ///
  /// 일정 조율 상세 조회.
  ///
  /// 인증 선택적: 접근 권한이 있는 경우 조회 가능합니다.
  /// - PUBLIC: 인증 없이도 조회 가능 (현재는 인증 필수로 처리).
  /// - ALLOWED_EMAILS: 허용된 이메일 사용자만 조회 가능 (인증 필수).
  ///
  /// Note: PUBLIC 레벨의 비인증 접근은 추후 구현 예정.
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/meetings/{meeting_id}')
  Future<MeetingRead> readMeetingV1MeetingsMeetingIdGet({
    @Path('meeting_id') required String meetingId,
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
  /// 인증 필수: 소유자만 삭제 가능합니다.
  @DELETE('/v1/meetings/{meeting_id}')
  Future<void> deleteMeetingV1MeetingsMeetingIdDelete({
    @Path('meeting_id') required String meetingId,
    @DioOptions() RequestOptions? options,
  });

  /// Create Participant.
  ///
  /// 참여자 등록.
  ///
  /// 인증 필수: 접근 권한이 있는 사용자만 참여 가능합니다.
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
  /// 인증 필수: 본인의 참여 시간만 설정 가능합니다.
  /// 기존 시간 슬롯을 모두 삭제하고 새로운 시간 슬롯을 설정합니다.
  ///
  /// :param meeting_id: 일정 조율 ID.
  /// :param participant_id: 참여자 ID (쿼리 파라미터).
  /// :param time_slots: 시간 슬롯 리스트 (요청 본문).
  ///
  /// [participantId] - 참여자 ID.
  @PUT('/v1/meetings/{meeting_id}/availability')
  Future<List<TimeSlotRead>> setAvailabilityV1MeetingsMeetingIdAvailabilityPut({
    @Path('meeting_id') required String meetingId,
    @Query('participant_id') required String participantId,
    @Body() required List<TimeSlotCreate> body,
    @DioOptions() RequestOptions? options,
  });

  /// Get Availability.
  ///
  /// 전체 참여자의 가능 시간 조회.
  ///
  /// 인증 선택적: 접근 권한이 있는 경우 조회 가능합니다.
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
  /// 인증 선택적: 접근 권한이 있는 경우 조회 가능합니다.
  /// 모든 참여자의 시간 선택을 집계하여 겹치는 시간대와 인원 수를 계산합니다.
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/meetings/{meeting_id}/result')
  Future<MeetingResultRead> getMeetingResultV1MeetingsMeetingIdResultGet({
    @Path('meeting_id') required String meetingId,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });
}
