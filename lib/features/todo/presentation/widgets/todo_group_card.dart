import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 할 일 그룹 카드. 대시보드와 그룹 고르기에서 쓴다.
class TodoGroupCard extends StatelessWidget {
  final TodoGroupRead group;
  final VoidCallback onTap;

  const TodoGroupCard({super.key, required this.group, required this.onTap});

  /// 카드를 늘어놓는 격자. 칸 폭은 [_maxWidth]까지 두고 넓은 화면은 열을 늘리며,
  /// 칸 높이는 이름 두 줄·설명 두 줄이 들어가게 글자 크기로 잰다.
  static SliverGridDelegate gridDelegate(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    double lines(TextStyle? style, int count) {
      final painter = TextPainter(
        text: TextSpan(text: '가', style: style),
        textScaler: scaler,
        textDirection: TextDirection.ltr,
      )..layout();
      final height = painter.height * count;
      painter.dispose();
      return height;
    }

    final content =
        _iconBox +
        _gap +
        lines(_nameStyle(theme), 2) +
        lines(_descriptionStyle(theme), 2) +
        _gap;
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: _maxWidth,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      // 카드 바깥 여백(4×2)·테두리(2×2)·안쪽 여백(16×2)
      mainAxisExtent: content + 8 + 4 + 32,
    );
  }

  static const _maxWidth = 240.0;
  static const _iconBox = 40.0;
  static const _gap = 12.0;

  static TextStyle? _nameStyle(ThemeData theme) =>
      theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      );

  static TextStyle? _descriptionStyle(ThemeData theme) => theme
      .textTheme
      .bodySmall
      ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupColor = HexColor.fromHex(group.color);

    return Card(
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: groupColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 (아이콘 + 상태)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: groupColor.withValues(alpha: 0.15),
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        color: groupColor,
                        size: 24,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),

                const SizedBox(height: _gap),

                // 그룹 이름
                Text(
                  group.name,
                  style: _nameStyle(theme),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // 설명 (있는 경우)
                if (group.description != null &&
                    group.description!.isNotEmpty) ...[
                  Text(
                    group.description!,
                    style: _descriptionStyle(theme),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
