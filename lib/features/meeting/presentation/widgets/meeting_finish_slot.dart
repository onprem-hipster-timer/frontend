import 'dart:async';

import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_autosave.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_finish_action.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_finish_slot_view.dart';

/// 모임 화면의 '저장하기' 자리. 이번에 내 시간을 바꾸면 나타나 저절로 저장하는 상태([MeetingAutosave])를 단추와
/// 함께 보인다: 저장하는 중, 저장했음(누르지 않아도 된다), 저장하지 못함. 단추를 누르면 남은 저장을 기다려(저장하지
/// 못한 것은 다시 보내) 모두 저장했을 때만 입력을 마쳤다고 알리고 추천 시간([slotsKey])이 보이게 굴린다. 마친
/// 뒤에는 다음에 바꿀 때까지 조용하고, 또 바꾸면 저장하는 중부터 다시 보인다.
///
/// Ctrl+S(macOS·iOS는 Cmd+S)는 그때 누를 수 있는 단추를 누른다. 누를 단추가 없어도(바꾸기 전, 누른 뒤 기다리는
/// 중, 마친 뒤) 키를 받아 브라우저가 페이지 저장을 열지 않는다. 초점이 어디 있든 받도록 `HardwareKeyboard`에
/// 달고, 이 화면 위에 시트·대화상자·다른 화면이 있으면 받지 않는다.
///
/// 모양과 키 받기는 [MeetingFinishSlotView]
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
  /// 이번에 내 시간을 바꿨는지. 바꾸기 전에는 두지 않는다
  var _changed = false;

  /// 누른 뒤의 상태(기다리는 중, 마침, 저장하지 못함). null이면 누르지 않았거나 누른 뒤 또 바꿔서 저절로
  /// 저장하는 상태를 보인다
  MeetingFinishPhase? _pressed;

  MeetingBoardNotifierProvider get _provider =>
      meetingBoardProvider(widget.meetingId);

  @override
  void initState() {
    super.initState();
    final status = ref.read(_provider).value?.status;
    _changed = status != null && status != MeetingSaveStatus.idle;
  }

  /// Ctrl+S(macOS·iOS는 Cmd+S)를 받으면 그때 누를 수 있는 단추를 누른다
  void _onSaveKey() {
    final status = ref.read(_provider).value?.status;
    if (_phaseOf(status)?.pressable ?? false) unawaited(_finish());
  }

  /// 보일 상태. 바꾸기 전이면 null이다
  MeetingFinishPhase? _phaseOf(MeetingSaveStatus? status) {
    if (!_changed) return null;
    return _pressed ??
        switch (status) {
          MeetingSaveStatus.saved => MeetingFinishPhase.autosaved,
          MeetingSaveStatus.failed => MeetingFinishPhase.failed,
          _ => MeetingFinishPhase.autosaving,
        };
  }

  Future<void> _finish() async {
    setState(() => _pressed = MeetingFinishPhase.saving);
    final saved = await ref.read(_provider.notifier).finishSaving();
    if (!mounted) return;
    setState(
      () => _pressed = saved
          ? MeetingFinishPhase.done
          : MeetingFinishPhase.failed,
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
    // 내 시간을 바꾸면(저장을 기다리면) 저절로 저장하는 상태로 돌아간다. 누른 뒤 기다리는 동안은 그대로 둔다
    ref.listen(_provider.select((state) => state.value?.status), (_, status) {
      if (status == MeetingSaveStatus.saving &&
          _pressed != MeetingFinishPhase.saving) {
        setState(() {
          _changed = true;
          _pressed = null;
        });
      }
    });
    return MeetingFinishSlotView(
      phase: _phaseOf(
        ref.watch(_provider.select((state) => state.value?.status)),
      ),
      pinned: widget.pinned,
      onPressed: _finish,
      onSaveKey: _onSaveKey,
    );
  }
}
