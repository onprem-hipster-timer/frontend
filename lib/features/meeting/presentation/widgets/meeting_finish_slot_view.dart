import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart'
    show HardwareKeyboard, LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_finish_action.dart';

/// 모임 화면의 '저장하기' 자리. [phase]가 null(바꾸기 전)이면 비어 있고, 아니면 저장 상태를 단추와 함께
/// 보인다([MeetingFinishAction]).
///
/// Ctrl+S(macOS·iOS는 Cmd+S)를 받을 때마다 [onSaveKey]를 부른다. 누를 단추가 없어도 키를 받아 브라우저가
/// 페이지 저장을 열지 않는다. 초점이 어디 있든 받도록 [HardwareKeyboard]에 달고, 이 화면 위에
/// 시트·대화상자·다른 화면이 있으면 받지 않는다
class MeetingFinishSlotView extends StatefulWidget {
  const MeetingFinishSlotView({
    super.key,
    required this.phase,
    required this.pinned,
    required this.onPressed,
    required this.onSaveKey,
  });

  /// 보일 상태. null이면 바꾸기 전이다
  final MeetingFinishPhase? phase;

  /// 좁은 화면 아래에 붙는지
  final bool pinned;
  final VoidCallback onPressed;
  final VoidCallback onSaveKey;

  @override
  State<MeetingFinishSlotView> createState() => _MeetingFinishSlotViewState();
}

class _MeetingFinishSlotViewState extends State<MeetingFinishSlotView> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  /// Ctrl+S(macOS·iOS는 Cmd+S)를 받았는지 돌려준다. 받으면 엔진이 브라우저의 기본 동작을 막는다
  bool _onKey(KeyEvent event) {
    final apple = switch (defaultTargetPlatform) {
      TargetPlatform.macOS || TargetPlatform.iOS => true,
      _ => false,
    };
    final save = SingleActivator(
      LogicalKeyboardKey.keyS,
      control: !apple,
      meta: apple,
    );
    if (!save.accepts(event, HardwareKeyboard.instance) ||
        ModalRoute.isCurrentOf(context) == false) {
      return false;
    }
    widget.onSaveKey();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.phase;
    if (phase == null) return const SizedBox.shrink();
    return MeetingFinishAction(
      phase: phase,
      pinned: widget.pinned,
      onPressed: widget.onPressed,
    );
  }
}
