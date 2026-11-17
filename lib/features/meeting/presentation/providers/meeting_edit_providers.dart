import 'package:dio/dio.dart' show DioException;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/auth_selectors.dart';
import 'package:momeet/features/meeting/domain/meeting_edit.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

/// 모임 설정 화면이 고칠 값
@immutable
class MeetingEditSource {
  const MeetingEditSource(this.base, {required this.hasAnswers});

  final MeetingEditBase base;

  /// 참여자가 넣은 답이 있는지(저장 전 알림은 이때만 보인다)
  final bool hasAnswers;
}

/// 모임 설정 저장의 결과
@immutable
class MeetingEditOutcome {
  const MeetingEditOutcome({
    required this.base,
    this.saved = const {},
    this.unsaved = const {},
    this.error,
  });

  /// 지금 서버의 값(저장하지 못한 것이 있으면 다시 읽은 값)
  final MeetingEditBase base;

  final Set<MeetingEditPart> saved;
  final Set<MeetingEditPart> unsaved;

  /// 저장하지 못한 요청의 오류
  final Object? error;

  bool get complete => unsaved.isEmpty;
}

/// 모임 설정의 요청: 불러오기, 차례대로 저장하기, 지우기.
///
/// 테스트: test/features/meeting/presentation/providers/meeting_edit_requests_test.dart
class MeetingEditRequests {
  const MeetingEditRequests(this._meetings, this._visibility);

  final MeetingsClient _meetings;
  final VisibilityClient _visibility;

  /// 모임 [meetingId]의 설정. 주인([userId])이 아니면 null이고 공개 범위와 답은 읽지 않는다
  Future<MeetingEditSource?> load(
    String meetingId, {
    required String? userId,
  }) async {
    final meeting = await _meetings.readMeetingV1MeetingsMeetingIdGet(
      meetingId: meetingId,
    );
    if (userId == null || meeting.ownerId != userId) return null;
    final audience = await _audience(meeting);
    final availability = await _meetings
        .getAvailabilityV1MeetingsMeetingIdAvailabilityGet(
          meetingId: meetingId,
        );
    return MeetingEditSource(
      MeetingEditBase(meeting: meeting, audience: audience),
      hasAnswers: availability.any((entry) => entry.timeSlots.isNotEmpty),
    );
  }

  /// [steps]를 차례대로 보낸다. 하나가 실패하면 뒤 요청은 보내지 않고(앞 요청에 기대어 순서를 정했다) 서버의
  /// 값을 다시 읽어 저장한 것·저장하지 못한 것과 함께 돌려준다. 다시 읽지 못하면 받은 응답으로 맞춘 값이다
  Future<MeetingEditOutcome> save(
    MeetingEditBase base,
    List<MeetingEditStep> steps,
  ) async {
    final id = base.meeting.id;
    var meeting = base.meeting;
    var audience = base.audience;
    final saved = <MeetingEditPart>{};
    for (final (index, step) in steps.indexed) {
      try {
        switch (step) {
          case MeetingFieldsStep(:final body):
            meeting = await _meetings.updateMeetingV1MeetingsMeetingIdPatch(
              meetingId: id,
              body: body,
            );
          case MeetingVisibilityStep(:final body):
            audience = MeetingAudience.of(
              await _visibility
                  .setVisibilityV1VisibilityResourceTypeResourceIdPut(
                    resourceType: ResourceType.meeting,
                    resourceId: id,
                    body: body,
                  ),
            );
        }
        saved.addAll(step.parts);
      } on Exception catch (error) {
        return MeetingEditOutcome(
          base:
              await _reread(id) ??
              MeetingEditBase(meeting: meeting, audience: audience),
          saved: saved,
          unsaved: {for (final rest in steps.skip(index)) ...rest.parts},
          error: error,
        );
      }
    }
    return MeetingEditOutcome(
      base: MeetingEditBase(meeting: meeting, audience: audience),
      saved: saved,
    );
  }

  /// 모임을 지운다(참여자의 답과 게스트도 함께 지워진다). 2xx 응답이면 본문과 상관없이 끝난다
  Future<void> delete(String meetingId) =>
      _meetings.deleteMeetingV1MeetingsMeetingIdDelete(meetingId: meetingId);

  Future<MeetingEditBase?> _reread(String meetingId) async {
    try {
      final meeting = await _meetings.readMeetingV1MeetingsMeetingIdGet(
        meetingId: meetingId,
      );
      return MeetingEditBase(
        meeting: meeting,
        audience: await _audience(meeting),
      );
    } on Exception {
      return null;
    }
  }

  /// 공개 범위. 정한 적이 없으면(404) 미팅이 알려 준 수준이고, 그것도 없으면 비공개(나만)다
  Future<MeetingAudience> _audience(MeetingRead meeting) async {
    try {
      return MeetingAudience.of(
        await _visibility.getVisibilityV1VisibilityResourceTypeResourceIdGet(
          resourceType: ResourceType.meeting,
          resourceId: meeting.id,
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;
      return MeetingAudience(
        meeting.visibilityLevel ?? VisibilityLevel.private,
      );
    }
  }
}

final meetingEditRequestsProvider = Provider<MeetingEditRequests>(
  (ref) => MeetingEditRequests(
    ref.watch(meetingsApiProvider),
    ref.watch(visibilityApiProvider),
  ),
);

/// 모임 설정 화면이 고칠 값. 로그인한 사람이 주인이 아니면 null이다
final meetingEditSourceProvider = FutureProvider.autoDispose
    .family<MeetingEditSource?, String>(
      (ref, meetingId) => ref
          .watch(meetingEditRequestsProvider)
          .load(
            meetingId,
            userId: ref.watch(currentUserProvider.select((user) => user?.id)),
          ),
    );
