import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/visibility/presentation/widgets/shared_by_text.dart';

/// 다른 사람이 공유한 항목 위에 두는 안내. 공유한 사람([SharedByText])과 [message]를 보인다
class SharedNotice extends StatelessWidget {
  const SharedNotice({super.key, required this.ownerId, required this.message});

  final String? ownerId;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.people_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SharedByText(
                    ownerId: ownerId,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
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
