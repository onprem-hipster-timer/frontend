import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_guest_import.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 방문자의 모임 화면 위: 이 기기에 이 모임의 게스트 세션을 따로 두었으면(정규 유저로 바꾸려다 로그인을 그만둠)
/// '게스트로 계속하기'로 그 게스트로 돌아간다. 세션이 끝났으면 그렇다고 알린다. 따로 둔 것은 쓰거나 끝난 것을
/// 알면 지운다
class MeetingKeptGuestNotice extends ConsumerStatefulWidget {
  const MeetingKeptGuestNotice({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<MeetingKeptGuestNotice> createState() =>
      _MeetingKeptGuestNoticeState();
}

class _MeetingKeptGuestNoticeState
    extends ConsumerState<MeetingKeptGuestNotice> {
  var _busy = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    final provider = keptGuestSessionExistsProvider(widget.meetingId);
    final messenger = ScaffoldMessenger.of(context);
    var continued = false;
    try {
      continued = await ref
          .read(authProvider.notifier)
          .continueAsKeptGuest(widget.meetingId);
    } on Exception {
      if (mounted) setState(() => _busy = false);
      messenger.showAppSnackBar('지금은 게스트로 돌아갈 수 없어요. 잠시 뒤 다시 시도해 주세요');
      return;
    }
    if (!continued) {
      messenger.showAppSnackBar('게스트 세션이 끝나 이어서 쓸 수 없어요');
      ref.invalidate(provider);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final kept = ref
        .watch(keptGuestSessionExistsProvider(widget.meetingId))
        .value;
    if (kept != true) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Icon(Icons.person_outline, size: 18, color: color),
          Text(
            '이 기기에 게스트로 넣던 시간이 있어요',
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
          TextButton(
            onPressed: _busy ? null : _continue,
            child: const Text('게스트로 계속하기'),
          ),
        ],
      ),
    );
  }
}
