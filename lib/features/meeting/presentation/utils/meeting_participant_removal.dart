import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 주인이 [participant]를 뺀다. 화면에서 바로 빼고 되돌리기 알림을 띄운 뒤, 알림이 되돌리기 없이 닫히면
/// 요청을 보낸다. 보내지 못하면 그 참여자가 다시 보이고 알린다. 화면을 떠난 뒤에도 같다.
Future<void> removeMeetingParticipant(
  BuildContext context,
  WidgetRef ref,
  String meetingId,
  ParticipantRead participant,
) async {
  final notifier = ref.read(meetingBoardProvider(meetingId).notifier);
  final messenger = ScaffoldMessenger.of(context);
  final who = participant.isGuest
      ? '게스트 ${participant.displayName}'
      : participant.displayName;
  notifier.remove(participant.id);
  final undone = await messenger.showAppUndoSnackBar(
    '${who.withJosa('을', '를')} 뺐습니다',
  );
  if (undone) return notifier.undoRemove(participant.id);
  try {
    await notifier.confirmRemove(participant.id);
  } catch (error) {
    if (messenger.mounted) {
      messenger.showAppSnackBar(
        '${who.withJosa('을', '를')} 빼지 못했습니다: $error',
        kind: AppNoticeKind.error,
      );
    }
  }
}
