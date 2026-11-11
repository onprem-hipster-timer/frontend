import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 하위 할 일 개수 배지
class TodoChildCountBadge extends StatelessWidget {
  const TodoChildCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.lgAll,
        ),
        child: Text('$count', style: theme.textTheme.labelSmall),
      ),
    );
  }
}
