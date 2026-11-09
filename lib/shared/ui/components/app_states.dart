import 'package:material_ui/material_ui.dart';

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
    return _StateFrame(
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
    return _StateFrame(
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

/// 불러오는 중 표시. [message]를 주면 아래에 보인다.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// 높이가 정해진 곳에서는 가운데 두고 칸보다 길면 굴리고, 아니면 내용 높이로 그린다.
class _StateFrame extends StatelessWidget {
  const _StateFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedHeight
          ? Center(child: SingleChildScrollView(child: content))
          : Center(child: content),
    );
  }
}
