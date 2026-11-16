import 'package:dio/dio.dart' show DioException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/auth/guest_user.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent_step.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_not_found.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 게스트가 모임을 불러오지 못했을 때.
///
/// - 약관이 바뀌었으면(428) 다시 동의를 받는다.
/// - 거절되면(403) 세션이 남았는지 본다. 세션이 끝났으면(주인이 뺐거나 게스트 기간이 끝나 게스트가 지워졌다)
///   미인증이 되어 방문자 화면으로 바뀌고 그렇다고 알린다. 세션이 남았으면 모임이 지금 게스트를 받지 않는
///   것이라 그렇다고 하고 다시 시도와 로그아웃을 둔다(게스트 정보는 남는다).
/// - 그 밖에는 불러오지 못했다고 하고 [onRetry]를 둔다.
class MeetingGuestProblem extends ConsumerStatefulWidget {
  const MeetingGuestProblem({
    super.key,
    required this.meetingId,
    required this.guest,
    required this.error,
    required this.onRetry,
  });

  final String meetingId;
  final GuestUser guest;
  final Object error;
  final VoidCallback onRetry;

  @override
  ConsumerState<MeetingGuestProblem> createState() =>
      _MeetingGuestProblemState();
}

class _MeetingGuestProblemState extends ConsumerState<MeetingGuestProblem> {
  /// 거절된 뒤 세션이 남았는지 확인한 결과. 확인하는 동안 null
  Future<bool>? _sessionAlive;

  int? get _status => switch (widget.error) {
    DioException(:final response?) => response.statusCode,
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    // 화면에 붙은 뒤 확인한다(알림을 띄울 곳을 찾는다)
    if (_status == 403) _sessionAlive = Future(_checkSession);
  }

  Future<bool> _checkSession() async {
    final messenger = ScaffoldMessenger.of(context);
    final token = await ref.read(authProvider.notifier).refreshAccessToken();
    if (token == null && messenger.mounted) {
      messenger.showAppSnackBar('이 ${Terms.meeting}의 게스트 정보가 지워졌습니다');
    }
    return token != null;
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authProvider.notifier).signOut();
    } on Exception catch (e) {
      if (mounted) {
        showAppSnackBar(context, '로그아웃하지 못했습니다: $e', kind: AppNoticeKind.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAgree = ref.watch(turnstileFactoryProvider) != null;
    return switch (_status) {
      428 when canAgree => MeetingGuestConsentStep(
        meetingId: widget.meetingId,
        guest: widget.guest,
        onAgreed: widget.onRetry,
      ),
      404 => const MeetingNotFound(),
      403 => FutureBuilder(
        future: _sessionAlive,
        builder: (context, snapshot) => switch (snapshot) {
          AsyncSnapshot(hasData: true, data: true) => AppErrorState(
            title: '지금은 게스트로 이 ${Terms.meeting.withJosa('을', '를')} 볼 수 없습니다',
            error:
                '${Terms.meeting} 주인이 게스트 참여나 공개를 껐습니다. '
                '다시 열리면 남긴 시간 그대로 이어서 쓸 수 있습니다.',
            onRetry: widget.onRetry,
            secondaryLabel: '로그아웃',
            secondaryIcon: Icons.logout,
            onSecondary: _signOut,
          ),
          AsyncSnapshot(hasError: true) => AppErrorState(
            title: '${Terms.meeting.withJosa('을', '를')} 불러오지 못했습니다',
            error: snapshot.error,
            onRetry: widget.onRetry,
          ),
          _ => const AppLoading(),
        },
      ),
      _ => AppErrorState(
        title: '${Terms.meeting.withJosa('을', '를')} 불러오지 못했습니다',
        error: widget.error,
        onRetry: widget.onRetry,
        secondaryLabel: '로그아웃',
        secondaryIcon: Icons.logout,
        onSecondary: _signOut,
      ),
    };
  }
}
