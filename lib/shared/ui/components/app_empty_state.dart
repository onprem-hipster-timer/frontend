import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/components/app_state_frame.dart';

/// 내용이 없을 때의 안내. [actionLabel]과 [onAction]을 주면 아래에 버튼을 둔다.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.actionIcon = Icons.add,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final message = this.message;
    final actionLabel = this.actionLabel;
    return AppStateFrame(
      children: [
        Icon(icon, size: 64, color: muted.withValues(alpha: 0.6)),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon),
            label: Text(actionLabel),
          ),
        ],
      ],
    );
  }
}
