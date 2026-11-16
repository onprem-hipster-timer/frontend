import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/auth/guest_user.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_participant_removal.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_schedule.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_account_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_problem.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_sheet.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_layout.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_sheet.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_not_found.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_participants_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 로그인한 회원·게스트의 모임 화면 본문: 지금 계정, 내 시간 격자, 링크, 일정 참여자, 선택된 일정.
///
/// 지금 계정('OO 계정으로 진행 중입니다')은 방문자의 로그인 상자 자리(넓으면 오른쪽 칸 맨 위, 좁으면 격자 위)다.
/// 넓으면 격자 오른쪽에 계정 → 링크 → 일정 참여자 → 선택된 일정, 좁으면 계정 → 격자 → 선택된 일정 → 일정
/// 참여자 → 링크 순서다(칠하기가 이 화면의 일이고, 그 결과가 바로 아래에 보이게). 볼 수 없는 모임은 없는
/// 모임과 같다.
///
/// [guest]면 게스트 이름과 로그아웃을 보이고, 달력이 없어 카드에 '내 달력에 일정 만들기'가 없다. '편집'은
/// 게스트의 이름 바꾸기와 게스트 계정 지우기([showMeetingGuestSheet])다. 불러오지
/// 못하면 [MeetingGuestProblem]이 까닭(약관 동의, 게스트를 받지 않음, 지워진 게스트)에 맞게 보인다.
class MeetingMemberBody extends ConsumerWidget {
  const MeetingMemberBody({super.key, required this.meetingId, this.guest});

  final String meetingId;
  final GuestUser? guest;

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
            final guest = this.guest;
            final slots = MeetingSlotsPanel(
              board: board,
              onAddToCalendar: guest != null
                  ? null
                  : (run) => addMeetingRunToCalendar(context, board, run),
            );
            final participants = MeetingParticipantsPanel(
              board: board,
              // 게스트의 이름 바꾸기·지우기는 확인 위젯이 있어야 한다
              onRename: guest != null
                  ? ref.watch(turnstileFactoryProvider) == null
                        ? null
                        : () => showMeetingGuestSheet(
                            context,
                            ref,
                            meetingId: meetingId,
                            guest: guest,
                          )
                  : () => showMeetingNameSheet(
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
            final account = _Account(guest: guest);
            return MeetingLayout(
              main: availability,
              side: [account, link, participants, slots],
              stacked: [account, availability, slots, participants, link],
            );
          },
          loading: () => const AppLoading(),
          error: (error, _) =>
              _LoadError(meetingId: meetingId, guest: guest, error: error),
        );
  }
}

/// 불러오지 못했을 때. 게스트는 까닭에 맞게([MeetingGuestProblem]), 회원은 찾을 수 없음이나 다시 시도
class _LoadError extends ConsumerWidget {
  const _LoadError({
    required this.meetingId,
    required this.guest,
    required this.error,
  });

  final String meetingId;
  final GuestUser? guest;
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void retry() {
      ref.invalidate(meetingProvider(meetingId));
      ref.invalidate(meetingBoardProvider(meetingId));
    }

    if (guest case final guest?) {
      return MeetingGuestProblem(
        // 다시 불러와 또 거절되면 처음부터 다시 본다
        key: ObjectKey(error),
        meetingId: meetingId,
        guest: guest,
        error: error,
        onRetry: retry,
      );
    }
    return isMeetingNotFound(error)
        ? const MeetingNotFound()
        : AppErrorState(
            title: '${Terms.meeting.withJosa('을', '를')} 불러오지 못했습니다',
            error: error,
            onRetry: retry,
          );
  }
}

/// 로그인 상자 자리의 지금 계정. 회원은 계정 이메일, 게스트는 게스트 이름과 로그아웃
class _Account extends ConsumerWidget {
  const _Account({required this.guest});

  final GuestUser? guest;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authProvider.notifier).signOut();
    } on Exception catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, '로그아웃하지 못했습니다: $e', kind: AppNoticeKind.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guest = this.guest;
    if (guest == null) {
      return MeetingAccountPanel(
        text: '${ref.watch(currentUserProvider)?.email} 계정으로 진행 중입니다',
      );
    }
    return MeetingAccountPanel(
      text: '게스트 ${guest.name.withJosa('으로', '로')} 진행 중입니다',
      guest: true,
      onSignOut: () => _signOut(context, ref),
    );
  }
}
