import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/turnstile/turnstile.dart';

/// 확인 상자와 그 아래 안내. 불러오지 못했거나 확인하지 못했으면 알리고 다시 하는 단추를 둔다.
///
/// 불러오지 못했으면 빈 상자는 두지 않는다.
class TurnstileField extends StatelessWidget {
  const TurnstileField({super.key, required this.controller});

  final TurnstileController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.status,
      builder: (context, status, _) {
        final problem = switch (status) {
          TurnstileStatus.unavailable => (
            '확인 상자를 불러오지 못했습니다. 네트워크를 확인해 주세요.',
            '다시 불러오기',
          ),
          TurnstileStatus.failed => ('사람인지 확인하지 못했습니다.', '다시 확인'),
          _ => null,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (status != TurnstileStatus.unavailable)
              controller.buildBox(context),
            if (problem case (final text, final action))
              _Problem(text: text, action: action, onPressed: controller.reset),
          ],
        );
      },
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
