import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 격자 바로 아래의 옅은 색 설명: 다른 참여자 농도(1명 ~ 모두). 내 칸의 색은 붓 고르기([MeetingBrushPicker])가 보인다
class MeetingGridLegend extends StatelessWidget {
  const MeetingGridLegend({
    super.key,
    required this.othersTotal,
    required this.hasSelf,
  });

  final int othersTotal;
  final bool hasSelf;

  @override
  Widget build(BuildContext context) {
    if (othersTotal == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = MeetingGridColors.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final levels = {
      for (var count = 1; count <= othersTotal; count++)
        availabilityShade(count, othersTotal),
    };
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('${hasSelf ? '다른 참여자' : '참여자'} 1명', style: style),
        const SizedBox(width: 6),
        for (final level in levels)
          _Swatch(
            Color.alphaBlend(colors.shade(level)!, colors.base),
            border: colors.border,
          ),
        if (othersTotal > 1) ...[
          const SizedBox(width: 4),
          Text('$othersTotal명', style: style),
        ],
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color, {required this.border});

  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: border),
        borderRadius: AppRadius.xsAll,
      ),
    );
  }
}
