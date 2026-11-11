import 'package:material_ui/material_ui.dart';

/// 화면 위쪽에 두는 짧은 안내. [title]을 주면 굵게 위에 둔다.
class AppHintCard extends StatelessWidget {
  const AppHintCard({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.info_outline,
  });

  final String message;
  final String? title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = this.title;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
