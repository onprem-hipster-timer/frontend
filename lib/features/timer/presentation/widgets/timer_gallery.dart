import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// [timers]를 갤러리의 쪽 순서로. 만든 순(오래된 것부터)이라 재개·일시정지로 쪽이 옮겨 가지 않는다
List<TimerRead> galleryOrder(List<TimerRead> timers) =>
    [...timers]..sort((a, b) {
      final created = a.createdAt.compareTo(b.createdAt);
      return created != 0 ? created : a.id.compareTo(b.id);
    });

/// 활성 타이머 갤러리
///
/// [timers]마다 한 쪽씩 [pageBuilder]로 그려 옆으로 넘기고, 보이는 쪽이 [focusedId] 타이머다.
/// 넘기면 [onFocus]로 그 타이머를 고르고, [focusedId]가 다른 곳에서 바뀌면 그 쪽으로 넘어간다.
/// 타이머가 늘거나 줄어도 보이던 타이머의 쪽을 그대로 보인다.
/// 아래에 쪽 표시를 두고, [arrows]면 그 양옆에 이전·다음 버튼을 둔다. 갤러리에 초점이 있으면 왼쪽·오른쪽 방향키로 넘긴다.
class TimerGallery extends StatefulWidget {
  const TimerGallery({
    super.key,
    required this.timers,
    required this.focusedId,
    required this.arrows,
    required this.onFocus,
    required this.pageBuilder,
  });

  final List<TimerRead> timers;
  final String? focusedId;
  final bool arrows;
  final ValueChanged<String> onFocus;
  final Widget Function(TimerRead timer) pageBuilder;

  @override
  State<TimerGallery> createState() => _TimerGalleryState();
}

class _TimerGalleryState extends State<TimerGallery> {
  late final _controller = PageController(initialPage: _focusedIndex);
  final _focusNode = FocusNode(debugLabel: 'timer-gallery');

  /// 보이는 쪽의 타이머 id
  late String? _shownId = widget.focusedId;

  /// 코드로 쪽을 옮기는 중. 그사이 지나는 쪽은 고르지 않는다
  bool _moving = false;

  int get _focusedIndex => math.max(
    0,
    widget.timers.indexWhere((timer) => timer.id == widget.focusedId),
  );

  @override
  void didUpdateWidget(TimerGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    final listChanged = !listEquals(
      [for (final timer in oldWidget.timers) timer.id],
      [for (final timer in widget.timers) timer.id],
    );
    if (listChanged || widget.focusedId != _shownId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 보이던 타이머의 쪽으로 바로 옮긴 뒤, 고른 타이머가 다르면 그 쪽으로 넘긴다
  Future<void> _sync() async {
    if (!mounted || !_controller.hasClients || _moving) return;
    final timers = widget.timers;
    final targetId = widget.focusedId;
    _moving = true;
    try {
      final shown = timers.indexWhere((timer) => timer.id == _shownId);
      if (shown >= 0 && shown != _controller.page?.round()) {
        _controller.jumpToPage(shown);
      }
      final target = _focusedIndex;
      if (target != _controller.page?.round()) {
        await _controller.animateToPage(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } finally {
      _moving = false;
    }
    if (!mounted || !_controller.hasClients) return;
    final page = _controller.page!.round();
    if (page < widget.timers.length) _shownId = widget.timers[page].id;
    if (_shownId == widget.focusedId) return;
    if (widget.focusedId != targetId) {
      // 옮기는 사이 다른 곳에서 또 골랐다
      _sync();
    } else if (_shownId != null) {
      // 옮기는 사이 사용자가 넘겼다
      widget.onFocus(_shownId!);
    }
  }

  void _onPageChanged(int index) {
    if (_moving) return;
    _shownId = widget.timers[index].id;
    widget.onFocus(_shownId!);
  }

  /// [index] 쪽의 타이머를 고른다. 쪽은 [didUpdateWidget]에서 넘긴다
  void _go(int index) {
    if (index < 0 || index >= widget.timers.length) return;
    widget.onFocus(widget.timers[index].id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timers = widget.timers;
    final index = _focusedIndex;

    final pages = GestureDetector(
      onTap: _focusNode.requestFocus,
      child: PageView.builder(
        key: const ValueKey('timer-gallery'),
        controller: _controller,
        itemCount: timers.length,
        onPageChanged: _onPageChanged,
        findChildIndexCallback: (key) {
          final found = timers.indexWhere(
            (timer) => key == ValueKey('timer-page-${timer.id}'),
          );
          return found < 0 ? null : found;
        },
        itemBuilder: (context, i) => KeyedSubtree(
          key: ValueKey('timer-page-${timers[i].id}'),
          child: widget.pageBuilder(timers[i]),
        ),
      ),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _go(index - 1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _go(index + 1),
      },
      child: Focus(
        focusNode: _focusNode,
        child: Column(
          children: [
            Expanded(child: pages),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.arrows)
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: '이전 타이머',
                    onPressed: index > 0 ? () => _go(index - 1) : null,
                  ),
                Semantics(
                  key: const ValueKey('timer-gallery-indicator'),
                  container: true,
                  label: '타이머 ${index + 1}/${timers.length}',
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < timers.length; i++)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == index
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.arrows)
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: '다음 타이머',
                    onPressed: index < timers.length - 1
                        ? () => _go(index + 1)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
