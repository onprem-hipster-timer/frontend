import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/tag/presentation/utils/tag_color_palette.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 태그·태그 그룹 폼의 색 고르기. [TagColorPalette]의 색을 동그라미로 늘어놓는다.
class TagColorPicker extends StatelessWidget {
  const TagColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Color selected;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const colors = TagColorPalette.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader('색상 선택'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < colors.length; i++)
              _Swatch(
                index: i,
                color: colors[i],
                selected: colors[i].toARGB32() == selected.toARGB32(),
                accent: primary,
                onTap: () => onChanged(colors[i]),
              ),
          ],
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.index,
    required this.color,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final int index;
  final Color color;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '색 ${index + 1}',
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 3,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: selected ? Icon(Icons.check, color: accent, size: 24) : null,
        ),
      ),
    );
  }
}
