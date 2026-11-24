import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_guest_import.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_import_notice_view.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 회원의 모임 화면 위: 따로 둔 게스트 세션의 시간을 옮기는 중이거나 옮기지 못했으면 조용한 한 줄(못 했으면
/// '다시 시도')이다. 옮기면 그렇다고, 첫 시도에서 게스트를 찾지 못하면 그렇다고 알린다([MeetingGuestImport])
class MeetingGuestImportNotice extends ConsumerWidget {
  const MeetingGuestImportNotice({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = meetingGuestImportProvider(meetingId);
    ref.listen(provider, (previous, next) {
      if (previous?.value == next.value) return;
      switch (next.value) {
        case MeetingGuestImportPhase.moved:
          showAppSnackBar(context, '게스트로 넣은 시간을 계정으로 옮겼어요');
        case MeetingGuestImportPhase.notFound:
          showAppSnackBar(context, '게스트로 넣은 시간을 찾지 못했어요. 이제 회원으로 참여해요');
        default:
          break;
      }
    });
    return MeetingGuestImportNoticeView(
      phase: ref.watch(provider).value,
      onRetry: () => ref.read(provider.notifier).retry(),
    );
  }
}
