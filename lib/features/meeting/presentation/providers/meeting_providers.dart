import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

/// 미팅 하나 (GET /v1/meetings/{meeting_id})
final meetingProvider = FutureProvider.autoDispose.family<MeetingRead, String>(
  (ref, meetingId) => ref
      .watch(meetingsApiProvider)
      .readMeetingV1MeetingsMeetingIdGet(meetingId: meetingId),
);
