import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_participant_removal.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_schedule.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_layout.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_sheet.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_participants_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 로그인한 회원의 모임 화면 본문: 내 시간 격자, 링크, 일정 참여자, 선택된 일정.
///
/// 넓으면 격자 오른쪽에 링크 → 일정 참여자 → 선택된 일정, 좁으면 격자 → 선택된 일정 → 일정 참여자 → 링크
/// 순서다(칠하기가 이 화면의 일이고, 그 결과가 바로 아래에 보이게).
class MeetingMemberBody extends ConsumerWidget {
  const MeetingMemberBody({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = meetingBoardProvider(meetingId);
    return ref
        .watch(provider)
        .when(
          data: (state) {
            final board = state.board;
            final notifier = ref.read(provider.notifier);
            final availability = MeetingAvailabilitySection(
              meeting: board.meeting,
              shading: board,
              status: state.status,
              onPaint: notifier.paint,
              onRetry: notifier.retrySave,
            );
            final slots = MeetingSlotsPanel(
              board: board,
              onAddToCalendar: (run) =>
                  addMeetingRunToCalendar(context, board, run),
            );
            final participants = MeetingParticipantsPanel(
              board: board,
              onRename: () => showMeetingNameSheet(
                context,
                meetingId: meetingId,
                currentName: board.me?.displayName ?? board.selfName,
              ),
              onRemove: (participant) => removeMeetingParticipant(
                context,
                ref,
                meetingId,
                participant,
              ),
            );
            final link = MeetingLinkPanel(meetingId: meetingId);
            return MeetingLayout(
              main: availability,
              side: [link, participants, slots],
              stacked: [availability, slots, participants, link],
            );
          },
          loading: () => const AppLoading(),
          error: (error, _) => AppErrorState(
            title: '${Terms.meeting.withJosa('을', '를')} 불러오지 못했습니다',
            error: error,
            onRetry: () {
              ref.invalidate(meetingProvider(meetingId));
              ref.invalidate(provider);
            },
          ),
        );
  }
}
