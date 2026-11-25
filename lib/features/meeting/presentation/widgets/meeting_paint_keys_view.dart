import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// 본문([child])에서 Ctrl+Z(macOS·iOS는 Cmd+Z)를 받으면 [onUndo]를, Ctrl+Y·Ctrl+Shift+Z(macOS·iOS는
/// Cmd+Shift+Z)를 받으면 [onRedo]를 부른다.
///
/// 화면을 열면 본문이 초점을 받아 누르지 않아도 키를 받는다. 초점이 본문 밖으로 가면 본문을 누를 때 다시 받는다.
/// 본문 안의 카드·단추에 초점이 있어도 받고, 시트·대화상자에 초점이 있으면(글 칸 포함) 그쪽이 받는다.
/// 본문을 누르고 있는 동안(끌어 칠하는 중)은 부르지 않는다.
class MeetingPaintKeysView extends StatefulWidget {
  const MeetingPaintKeysView({
    super.key,
    required this.onUndo,
    required this.onRedo,
    required this.child,
  });

  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final Widget child;

  @override
  State<MeetingPaintKeysView> createState() => _MeetingPaintKeysViewState();
}

class _MeetingPaintKeysViewState extends State<MeetingPaintKeysView> {
  final _focus = FocusNode(
    debugLabel: 'meeting-paint-keys',
    skipTraversal: true,
  );

  /// 본문을 누르고 있는 포인터
  final _pressed = <int>{};

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _press(PointerDownEvent event) {
    _pressed.add(event.pointer);
    if (!_focus.hasFocus) _focus.requestFocus();
  }

  /// 본문을 누르고 있지 않으면 [replay]를 부른다
  void _replay(VoidCallback replay) {
    if (_pressed.isNotEmpty) return;
    replay();
  }

  @override
  Widget build(BuildContext context) {
    final apple = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    void undo() => _replay(widget.onUndo);
    void redo() => _replay(widget.onRedo);
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyZ, control: !apple, meta: apple):
            undo,
        SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: !apple,
          meta: apple,
          shift: true,
        ): redo,
        if (!apple)
          const SingleActivator(LogicalKeyboardKey.keyY, control: true): redo,
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        includeSemantics: false,
        child: Listener(
          onPointerDown: _press,
          onPointerUp: (event) => _pressed.remove(event.pointer),
          onPointerCancel: (event) => _pressed.remove(event.pointer),
          child: widget.child,
        ),
      ),
    );
  }
}
