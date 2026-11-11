import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 태그 색 점(최대 2개), 첫 태그 이름, 나머지 수
class TodoTagIndicators extends StatelessWidget {
  const TodoTagIndicators({super.key, required this.tags});

  final List<TagRead> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tag in tags.take(2))
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Tooltip(
                message: tag.name,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(tag.color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          Flexible(
            child: Text(
              tags.first.name,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (tags.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                '+${tags.length - 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
