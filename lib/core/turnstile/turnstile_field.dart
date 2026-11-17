import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/turnstile/turnstile.dart';

/// 확인 상자와 그 아래 안내. 불러오지 못했거나 확인하지 못했으면 알리고 다시 하는 단추를 둔다.
///
/// 불러오지 못했으면 빈 상자는 두지 않는다. 사람이 상자 안에서 할 일이 생기면 상자를 보이게 굴리고
/// '확인 상자를 눌러 주세요'를 적는다(애니메이션을 줄였으면 움직임 없이 간다).
class TurnstileField extends StatefulWidget {
  const TurnstileField({super.key, required this.controller});

  final TurnstileController controller;

  @override
  State<TurnstileField> createState() => _TurnstileFieldState();
}

class _TurnstileFieldState extends State<TurnstileField> {
  final _box = GlobalKey();
  late TurnstileStatus _last;

  @override
  void initState() {
    super.initState();
    _last = widget.controller.status.value;
    widget.controller.status.addListener(_changed);
  }

  @override
  void didUpdateWidget(TurnstileField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.status.removeListener(_changed);
    widget.controller.status.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.status.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final status = widget.controller.status.value;
    final began =
        status == TurnstileStatus.interactive &&
        _last != TurnstileStatus.interactive;
    _last = status;
    if (!began) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _box.currentContext;
      if (box == null || !box.mounted) return;
      Scrollable.ensureVisible(
        box,
        duration: MediaQuery.disableAnimationsOf(box)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ValueListenableBuilder(
      valueListenable: controller.status,
      builder: (context, status, _) {
        final problem = switch (status) {
          TurnstileStatus.unavailable => (
            '확인 상자를 불러오지 못했습니다. 네트워크와 브라우저를 확인해 주세요.',
            '다시 불러오기',
          ),
          TurnstileStatus.failed => ('사람인지 확인하지 못했습니다.', '다시 확인'),
          _ => null,
        };
        return Column(
          key: _box,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (status != TurnstileStatus.unavailable)
              controller.buildBox(context),
            if (status == TurnstileStatus.interactive) const _Interactive(),
            if (problem case (final text, final action))
              _Problem(text: text, action: action, onPressed: controller.reset),
          ],
        );
      },
    );
  }
}

/// 사람이 상자 안에서 할 일이 있을 때의 한 줄
class _Interactive extends StatelessWidget {
  const _Interactive();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Semantics(
        liveRegion: true,
        child: Text(
          '확인 상자를 눌러 주세요',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// 확인 상자 아래의 문제 안내 한 줄과 다시 하는 단추
class _Problem extends StatelessWidget {
  const _Problem({
    required this.text,
    required this.action,
    required this.onPressed,
  });

  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          TextButton(onPressed: onPressed, child: Text(action)),
        ],
      ),
    );
  }
}
