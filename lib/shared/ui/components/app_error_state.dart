import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/components/app_state_frame.dart';

/// 불러오지 못했을 때의 안내. [onRetry]를 주면 '다시 시도'를, [secondaryLabel]과
/// [onSecondary]를 주면 그 앞에 다른 길(예: 돌아가기)을 둔다.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    this.error,
    this.onRetry,
    this.secondaryLabel,
    this.secondaryIcon = Icons.arrow_back,
    this.onSecondary,
  });

  final String title;

  /// 주면 제목 아래에 작게 보인다.
  final Object? error;
  final VoidCallback? onRetry;
  final String? secondaryLabel;
  final IconData secondaryIcon;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = this.error;
    final onRetry = this.onRetry;
    final secondaryLabel = this.secondaryLabel;
    final onSecondary = this.onSecondary;
    final hasActions =
        onRetry != null || (secondaryLabel != null && onSecondary != null);
    return AppStateFrame(
      children: [
        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (hasActions) ...[
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              if (secondaryLabel != null && onSecondary != null)
                OutlinedButton.icon(
                  onPressed: onSecondary,
                  icon: Icon(secondaryIcon),
                  label: Text(secondaryLabel),
                ),
              if (onRetry != null)
                FilledButton.tonalIcon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 시도'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
