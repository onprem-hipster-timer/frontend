import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 할 일 트리 위의 '루트로 이동' 칸. 끌고 있는 할 일을 놓을 수 있는 위치면 [highlighted]로 강조한다.
class TodoRootDropTargetView extends StatelessWidget {
  const TodoRootDropTargetView({super.key, required this.highlighted});

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isValidTarget = highlighted;
    final theme = Theme.of(context);

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isValidTarget
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: isValidTarget ? 2 : 1,
          style: BorderStyle.solid,
        ),
        borderRadius: AppRadius.mdAll,
        color: isValidTarget
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_upward,
              size: 16,
              color: isValidTarget
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              '루트로 이동',
              style: TextStyle(
                color: isValidTarget
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isValidTarget ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
