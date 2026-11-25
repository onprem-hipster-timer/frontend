import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/auth_selectors.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_paint_keys_view.dart';

/// 모임 화면 본문([child])에서 내가 칠한 것을 키보드로 한 번 칠한 단위씩 되돌리고(Ctrl+Z, macOS·iOS는 Cmd+Z)
/// 다시 칠한다(Ctrl+Y·Ctrl+Shift+Z, macOS·iOS는 Cmd+Shift+Z). 칠한 것과 같이 보이고 저장한다
/// ([MeetingBoardNotifier.undo]).
///
/// 화면을 열면 본문이 초점을 받아 격자를 누르지 않아도 키를 받는다. 초점이 본문 밖(머리띠)으로 가면 본문을 누를 때
/// 다시 받는다. 본문 안의 카드·단추에 초점이 있어도 받고, 시트·대화상자에 초점이 있으면(글 칸 포함) 그쪽이 받는다.
/// 본문을 누르고 있는 동안(끌어 칠하는 중)과 게스트가 거절되어 칠할 수 없는 동안은 아무것도 하지 않는다.
///
/// 키 받기는 [MeetingPaintKeysView]
class MeetingPaintKeys extends ConsumerWidget {
  const MeetingPaintKeys({
    super.key,
    required this.meetingId,
    required this.child,
  });

  final String meetingId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// 칠한 것을 되돌린다([redo]면 되돌린 것을 다시 칠한다). 게스트가 거절되었으면 하지 않는다
    void replay({required bool redo}) {
      if (ref.read(currentGuestDenialProvider) != null) return;
      final board = ref.read(meetingBoardProvider(meetingId).notifier);
      if (redo) {
        board.redo();
      } else {
        board.undo();
      }
    }

    return MeetingPaintKeysView(
      onUndo: () => replay(redo: false),
      onRedo: () => replay(redo: true),
      child: child,
    );
  }
}
