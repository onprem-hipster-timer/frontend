import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_headcount.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_layout.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_not_found.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 로그인하지 않은 방문자의 모임 화면 본문: 공개 모임의 사람 수 격자([headcount]), 로그인, 참여자 수, 링크.
///
/// 이름은 어디에도 보이지 않는다(참여자 칩·선택된 일정이 없다). [guests]면 로그인 옆에 'Guest'를 두고, 누르면
/// 그 자리에서 [guestForm]을 연다.
///
/// 넓으면 로그인 상자가 오른쪽 칸 맨 위에 있고, 칠하려 하면 [onNudged]를 부르고 그 상자를 보이게 굴리고 떤다.
/// 좁으면 로그인 상자를 두지 않고 화면 아래에 '내 시간 입력하기'를 붙여 두며, 그것을 누르거나 칠하려 하면
/// [onRequest]를 부른다. 없는 모임이면 '모임을 찾을 수 없습니다'와 로그인이다.
class MeetingVisitorBodyView extends StatefulWidget {
  const MeetingVisitorBodyView({
    super.key,
    required this.headcount,
    required this.guests,
    required this.keptGuestNotice,
    required this.guestForm,
    required this.link,
    required this.onLogin,
    required this.onNudged,
    required this.onRequest,
    required this.onRetry,
  });

  final AsyncValue<MeetingHeadcount> headcount;

  /// 게스트로 들어갈 수 있는지
  final bool guests;

  /// 격자 위의 '게스트로 계속하기' 자리
  final Widget keptGuestNotice;

  /// 'Guest'를 누르면 로그인 상자 안에 여는 게스트 폼
  final Widget guestForm;

  /// 모임 제목을 받아 '링크' 상자를 만든다
  final Widget Function(String title) link;
  final VoidCallback onLogin;

  /// 넓은 화면에서 칠하려 했다(로그인 상자를 보이고 떨기 전에 부른다)
  final VoidCallback onNudged;

  /// 좁은 화면에서 칠하려 했거나 '내 시간 입력하기'를 눌렀다
  final VoidCallback onRequest;
  final VoidCallback onRetry;

  @override
  State<MeetingVisitorBodyView> createState() => _MeetingVisitorBodyViewState();
}

class _MeetingVisitorBodyViewState extends State<MeetingVisitorBodyView> {
  final _login = GlobalKey();
  var _shakes = 0;
  var _guestOpen = false;

  /// 칠하려 한 사람에게 로그인을 묻는다. 좁으면 [MeetingVisitorBodyView.onRequest], 넓으면 옆의 로그인 상자로
  /// 데려간다
  void _nudge() {
    if (MeetingLayout.narrow(MediaQuery.sizeOf(context).width)) {
      return widget.onRequest();
    }
    widget.onNudged();
    setState(() => _shakes++);
    final box = _login.currentContext;
    if (box == null) return;
    Scrollable.ensureVisible(
      box,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.headcount.when(
      data: (headcount) {
        final guests = widget.guests;
        final availability = MeetingAvailabilitySection(
          meeting: headcount.meeting,
          shading: headcount,
          onLocked: _nudge,
        );
        final login = MeetingLoginPanel(
          key: _login,
          shakes: _shakes,
          onLogin: widget.onLogin,
          onGuest: guests ? () => setState(() => _guestOpen = true) : null,
          guestForm: guests && _guestOpen ? widget.guestForm : null,
          onCloseGuest: () => setState(() => _guestOpen = false),
        );
        final participants = _HeadcountPanel(headcount.participantCount);
        final link = widget.link(headcount.meeting.title);
        return MeetingLayout(
          main: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [widget.keptGuestNotice, availability],
          ),
          side: [login, participants, link],
          tertiary: [participants, link],
          bottom: _PaintAction(onPressed: widget.onRequest),
        );
      },
      loading: () => const AppLoading(),
      error: (error, _) => isMeetingNotFound(error)
          ? MeetingNotFound(onLogin: widget.onLogin)
          : AppErrorState(
              title: '${Terms.meeting.withJosa('을', '를')} 불러오지 못했습니다',
              error: error,
              onRetry: widget.onRetry,
            ),
    );
  }
}

/// 이름 없이 참여자 수만 보이는 '일정 참여자'
class _HeadcountPanel extends StatelessWidget {
  const _HeadcountPanel(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MeetingPanel(
      title: '일정 참여자',
      child: Text(
        count == 0 ? '아직 참여한 사람이 없습니다' : '$count명 참여 중',
        style: count == 0
            ? theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )
            : theme.textTheme.bodyLarge,
      ),
    );
  }
}

/// 좁은 화면 아래에 붙은 '내 시간 입력하기'. 누르면 로그인을 묻는다
class _PaintAction extends StatelessWidget {
  const _PaintAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('내 시간 입력하기'),
          ),
        ),
      ),
    );
  }
}
