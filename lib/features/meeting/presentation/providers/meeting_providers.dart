import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

part 'meeting_providers.g.dart';

/// 미팅 하나 (GET /v1/meetings/{meeting_id})
final meetingProvider = FutureProvider.autoDispose.family<MeetingRead, String>(
  (ref, meetingId) => ref
      .watch(meetingsApiProvider)
      .readMeetingV1MeetingsMeetingIdGet(meetingId: meetingId),
);

/// 미팅 만들기. 화면의 작업 상태는 [createMeetingMutation]이 담는다.
///
/// 사용 예: `createMeetingMutation.run(ref, (tsx) =>
/// tsx.get(meetingMutationsProvider.notifier).create(body, isPublic: true))`
@riverpod
class MeetingMutations extends _$MeetingMutations {
  @override
  void build() {}

  /// [body]로 미팅을 만든다. [isPublic]이면 링크가 있는 누구나 볼 수 있게 연다.
  ///
  /// 공개로 열지 못하면 만든 미팅을 지우고 그 오류를 던진다. 다시 눌러도 미팅이 둘 생기지 않는다.
  Future<MeetingRead> create(
    MeetingCreate body, {
    required bool isPublic,
  }) async {
    final meetings = ref.read(meetingsApiProvider);
    final meeting = await meetings.createMeetingV1MeetingsPost(body: body);
    if (!isPublic) return meeting;
    try {
      await ref
          .read(visibilityApiProvider)
          .setVisibilityV1VisibilityResourceTypeResourceIdPut(
            resourceType: ResourceType.meeting,
            resourceId: meeting.id,
            body: const VisibilityUpdate(level: VisibilityLevel.public),
          );
    } catch (_) {
      await meetings
          .deleteMeetingV1MeetingsMeetingIdDelete(meetingId: meeting.id)
          .then<void>((_) {}, onError: (_) {});
      rethrow;
    }
    return meeting;
  }
}

final createMeetingMutation = Mutation<MeetingRead>(label: 'createMeeting');
