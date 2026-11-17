import 'dart:async';

import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_autosave.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_finish_action.dart';

/// 모임 화면의 '저장하기' 자리. 이번에 내 시간을 바꾸면 나타나고, 누르면 남은 저장을 기다려(저장하지 못한 것은
/// 다시 보내) 모두 저장했을 때만 입력을 마쳤다고 알리고 추천 시간([slotsKey])이 보이게 굴린다. 마친 뒤에는 다음에
/// 바꿀 때까지 조용하다. 저장은 누르지 않아도 전처럼 저절로 된다([MeetingAutosave])
class MeetingFinishSlot extends ConsumerStatefulWidget {
  const MeetingFinishSlot({
    super.key,
    required this.meetingId,
    required this.slotsKey,
    required this.pinned,
  });

  final String meetingId;
  final GlobalKey slotsKey;

  /// 좁은 화면 아래에 붙는지
  final bool pinned;

  @override
  ConsumerState<MeetingFinishSlot> createState() => _MeetingFinishSlotState();
}

class _MeetingFinishSlotState extends ConsumerState<MeetingFinishSlot> {
  /// null이면 이번에 바꾼 것이 없어 두지 않는다
  MeetingFinishPhase? _phase;

  MeetingBoardNotifierProvider get _provider =>
      meetingBoardProvider(widget.meetingId);

  @override
  void initState() {
    super.initState();
    final status = ref.read(_provider).value?.status;
    if (status != null && status != MeetingSaveStatus.idle) {
      _phase = MeetingFinishPhase.ready;
    }
  }

  Future<void> _finish() async {
    setState(() => _phase = MeetingFinishPhase.saving);
    final saved = await ref.read(_provider.notifier).finishSaving();
    if (!mounted) return;
    setState(
      () =>
          _phase = saved ? MeetingFinishPhase.done : MeetingFinishPhase.failed,
    );
    if (!saved) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      '입력을 마쳤어요. 언제든 다시 고칠 수 있어요',
      Directionality.of(context),
    );
    _showSlots();
  }

  /// 추천 시간의 위를 화면 위(좁으면 머리띠 아래)에 맞춰 굴린다
  void _showSlots() {
    final slots = widget.slotsKey.currentContext;
    final box = slots?.findRenderObject();
    if (slots == null || box == null) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    final scrollable = Scrollable.maybeOf(slots);
    if (viewport == null || scrollable == null) return;
    // 좁으면 본문이 머리띠 뒤로 이어지므로 머리띠 높이만큼 덜 굴린다
    final header = widget.pinned ? MediaQuery.paddingOf(context).top + 8 : 0;
    final position = scrollable.position;
    final target = (viewport.getOffsetToReveal(box, 0).offset - header).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      position.jumpTo(target);
    } else {
      unawaited(
        position.animateTo(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 내 시간을 바꾸면(저장을 기다리면) 다시 누를 수 있다. 누른 뒤 기다리는 동안은 그대로 둔다
    ref.listen(_provider.select((state) => state.value?.status), (_, status) {
      if (status == MeetingSaveStatus.saving &&
          _phase != MeetingFinishPhase.saving) {
        setState(() => _phase = MeetingFinishPhase.ready);
      }
    });
    final phase = _phase;
    if (phase == null) return const SizedBox.shrink();
    return MeetingFinishAction(
      phase: phase,
      pinned: widget.pinned,
      onPressed: _finish,
    );
  }
}
