import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';

/// 붓 고르기: '가능'(기본)과 '불가능'. 고를 때마다 그 붓이 칠하는 칸 모양을 함께 보여 색 설명을 겸한다.
/// 늘리지 않고 앞쪽(왼쪽)에 둔다
class MeetingBrushPicker extends StatelessWidget {
  const MeetingBrushPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final MeetingAnswer value;
  final ValueChanged<MeetingAnswer> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = MeetingGridColors.of(context);
    final picker = SegmentedButton<MeetingAnswer>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        for (final (answer, label) in const [
          (MeetingAnswer.available, '가능'),
          (MeetingAnswer.unavailable, '불가능'),
        ])
          ButtonSegment(
            value: answer,
            label: Text(label),
            icon: CustomPaint(
              size: const Size.square(14),
              painter: _SwatchPainter(answer, colors),
            ),
          ),
      ],
      selected: {value},
      onSelectionChanged: (picked) => onChanged(picked.single),
    );
    return Align(alignment: AlignmentDirectional.centerStart, child: picker);
  }
}

/// 붓이 칠하는 칸의 작은 견본
class _SwatchPainter extends CustomPainter {
  const _SwatchPainter(this.answer, this.colors);

  final MeetingAnswer answer;
  final MeetingGridColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(3),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..color = answer == MeetingAnswer.available ? colors.mine : colors.base,
    );
    if (answer == MeetingAnswer.unavailable) {
      colors.paintUnavailable(canvas, shape);
    }
    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = colors.border,
    );
  }

  @override
  bool shouldRepaint(_SwatchPainter oldDelegate) =>
      oldDelegate.answer != answer || oldDelegate.colors != colors;
}
