import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/auth/guest_user.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_participant_removal.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_run_highlight.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_schedule.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_account_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_finish_slot.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_import_notice.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_problem.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_upgrade_prompt.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_sheet.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_layout.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_sheet.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_not_found.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_participants_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 로그인한 회원·게스트의 모임 화면 본문: 지금 계정, 내 시간 격자, 링크, 일정 참여자, 추천 시간.
///
/// 넓으면 격자 오른쪽에 계정('OO 계정으로 진행 중입니다', 방문자의 로그인 상자 자리) → 링크 → 일정 참여자
/// → 추천 시간을 상자로 둔다(추천 시간은 남은 높이를 채우고 그 안에서 굴린다). 좁으면 계정은 격자 앞의 조용한
/// 한 줄이고, 격자 → 추천 시간 → 일정 참여자
/// → 링크 순서로 뒤로 갈수록 덜 눈에 띈다(칠하기가 이 화면의 일이고, 그 결과가 바로 아래에 보이게). 볼 수
/// 없는 모임은 없는 모임과 같다.
///
/// [guest]면 게스트 이름과 로그아웃을 보이고, 달력이 없어 카드에 '내 달력에 일정 만들기'가 없다. '편집'은
/// 게스트의 이름 바꾸기와 게스트 계정 지우기([showMeetingGuestSheet])다. 불러오지
/// 못하면 [MeetingGuestProblem]이 까닭(약관 동의, 게스트를 받지 않음, 지워진 게스트)에 맞게 보인다.
///
/// 추천 시간 카드에 마우스를 올리거나 누르면 격자의 그 칸을 강조한다([MeetingRunHighlight]).
class MeetingMemberBody extends ConsumerStatefulWidget {
  const MeetingMemberBody({super.key, required this.meetingId, this.guest});

  final String meetingId;
  final GuestUser? guest;

  @override
  ConsumerState<MeetingMemberBody> createState() => _MeetingMemberBodyState();
}

class _MeetingMemberBodyState extends ConsumerState<MeetingMemberBody> {
  final _highlight = MeetingRunHighlight();

  /// '저장하기'가 마친 뒤 보이게 굴리는 추천 시간
  final _slotsKey = GlobalKey();

  @override
  void dispose() {
    _highlight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MeetingMemberBody(:meetingId) = widget;
    final provider = meetingBoardProvider(meetingId);
    return ref
        .watch(provider)
        .when(
          data: (state) {
            final guest = widget.guest;
            final denial = guest == null
                ? null
                : ref.watch(currentGuestDenialProvider);
            // 저장하다 거절되면 파이프라인이 적은 까닭의 화면이다
            if (guest != null && denial != null) {
              return _LoadError(meetingId: meetingId, guest: guest);
            }
            final board = state.board;
            final notifier = ref.read(provider.notifier);
            final availability = MeetingAvailabilitySection(
              meeting: board.meeting,
              shading: board,
              status: state.status,
              onPaint: notifier.paint,
              onRetry: notifier.retrySave,
              highlight: _highlight,
            );
            // 넓으면 오른쪽 칸, 좁으면 격자 아래에 하나만 그린다
            Widget slots({bool fill = false}) => KeyedSubtree(
              key: _slotsKey,
              child: MeetingSlotsPanel(
                board: board,
                fill: fill,
                highlight: _highlight,
                onAddToCalendar: guest != null
                    ? null
                    : (run) => addMeetingRunToCalendar(context, board, run),
              ),
            );
            final participants = _Participants(
              board: board,
              meetingId: meetingId,
              guest: guest,
            );
            final link = MeetingLinkPanel(
              meetingId: meetingId,
              title: board.meeting.title,
              owner: board.ownedByMe,
              level: board.meeting.visibilityLevel,
            );
            final account = _Account(meetingId: meetingId, guest: guest);
            return MeetingLayout(
              main: guest != null
                  ? availability
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MeetingGuestImportNotice(meetingId: meetingId),
                        availability,
                      ],
                    ),
              side: [account, link, participants],
              sideFill: slots(fill: true),
              header: account,
              secondary: [slots()],
              tertiary: [participants, link],
              action: (pinned) => MeetingFinishSlot(
                meetingId: meetingId,
                slotsKey: _slotsKey,
                pinned: pinned,
              ),
            );
          },
          loading: () => const AppLoading(),
          error: (error, _) => _LoadError(
            meetingId: meetingId,
            guest: widget.guest,
            error: error,
          ),
        );
  }
}

/// '일정 참여자'. 회원은 이 모임의 이름을, 게스트는 확인 위젯이 있을 때 게스트 이름을 바꾼다
class _Participants extends ConsumerWidget {
  const _Participants({
    required this.board,
    required this.meetingId,
    required this.guest,
  });

  final MeetingBoard board;
  final String meetingId;
  final GuestUser? guest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guest = this.guest;
    return MeetingParticipantsPanel(
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
      onRemove: (participant) =>
          removeMeetingParticipant(context, ref, meetingId, participant),
    );
  }
}

/// 거절 까닭을 지우고 모임을 다시 불러온다
void retryMeetingLoad(WidgetRef ref, String meetingId) {
  if (ref.read(currentGuestDenialProvider) != null) {
    ref.read(authProvider.notifier).guestDenialCleared();
  }
  ref.invalidate(meetingProvider(meetingId));
  ref.invalidate(meetingBoardProvider(meetingId));
}

/// 불러오지 못했을 때. 게스트는 까닭에 맞게([MeetingGuestProblem]), 회원은 찾을 수 없음이나 다시 시도
class _LoadError extends ConsumerWidget {
  const _LoadError({required this.meetingId, required this.guest, this.error});

  final String meetingId;
  final GuestUser? guest;

  /// 불러오기 오류. 저장하다 거절된 게스트는 오류 없이 거절 까닭만으로 온다
  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void retry() => retryMeetingLoad(ref, meetingId);
    final error = this.error;

    if (guest case final guest?) {
      return MeetingGuestProblem(
        meetingId: meetingId,
        guest: guest,
        denial: ref.watch(currentGuestDenialProvider),
        error: error,
        onRetry: retry,
      );
    }
    return error != null && isMeetingNotFound(error)
        ? const MeetingNotFound()
        : AppErrorState(
            title: '${Terms.meeting.withJosa('을', '를')} 불러오지 못했습니다',
            error: error,
            onRetry: retry,
          );
  }
}

/// 로그인 상자 자리의 지금 계정. 회원은 계정 이메일과 로그아웃, 게스트는 게스트 이름과 로그아웃, 정규 유저로 바꾸기
class _Account extends ConsumerWidget {
  const _Account({required this.meetingId, required this.guest});

  final String meetingId;
  final GuestUser? guest;

  /// 로그아웃한다. 보내는 중이거나 기다리는 내 시간 저장을 먼저 마치고(저장하지 못해도 묻지 않는다) 세션을
  /// 끝낸다. 모임 화면은 그 자리에서 방문자 화면이 된다
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(meetingBoardProvider(meetingId).notifier).finishSaving();
    if (!context.mounted) return;
    try {
      await ref.read(authProvider.notifier).signOut();
    } on Exception catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, '로그아웃하지 못했습니다: $e', kind: AppNoticeKind.error);
      }
    }
  }

  /// '안전한 정규 유저로 바꾸기': 무엇이 바뀌는지 묻고, 고르면 이 모임으로 돌아오는 로그인으로 간 뒤 게스트 세션을
  /// 끝내지 않고 따로 둔다(돌아오면 게스트 시간을 옮긴다).
  ///
  /// 게스트에서 벗어나면 계정이 바뀌어 라우터를 새로 만들고, 새 라우터는 브라우저 주소에서 시작한다. 그래서
  /// 로그인 화면으로 먼저 가 주소에 남긴 뒤에 따로 둔다
  Future<void> _upgrade(
    BuildContext context,
    WidgetRef ref,
    GuestUser guest,
  ) async {
    final meetingId = guest.meetingId;
    if (meetingId == null) return;
    final wide = !MeetingLayout.narrow(MediaQuery.sizeOf(context).width);
    final router = GoRouter.of(context);
    final auth = ref.read(authProvider.notifier);
    final back = router.namedLocation(
      AppRoute.meeting.name,
      pathParameters: {'meetingId': meetingId},
    );
    if (!await askGuestUpgrade(context, wide: wide)) return;
    router.goNamed(AppRoute.login.name, queryParameters: {'redirect': back});
    await WidgetsBinding.instance.endOfFrame;
    await auth.keepGuestForImport();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guest = this.guest;
    if (guest == null) {
      return MeetingAccountPanel(
        text: '${ref.watch(currentUserProvider)?.email} 계정으로 진행 중입니다',
        onSignOut: () => _signOut(context, ref),
      );
    }
    return MeetingAccountPanel(
      text: '게스트 ${guest.name.withJosa('으로', '로')} 진행 중입니다',
      guest: true,
      onSignOut: () => _signOut(context, ref),
      onUpgrade: () => _upgrade(context, ref, guest),
    );
  }
}
