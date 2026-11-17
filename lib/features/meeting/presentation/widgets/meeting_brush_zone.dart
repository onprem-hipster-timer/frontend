import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_brush_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_brush_picker.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 칠하기 조작 영역: 붓 고르기와 고른 붓으로 무엇을 칠하는지 한 줄([meetingBrushLine]). 붓 안내는 격자 전체에
/// 대한 말이라 붓 옆에 두고, 붓을 바꾸면 스크린 리더가 읽는다
class MeetingBrushZone extends StatelessWidget {
  const MeetingBrushZone({
    super.key,
    required this.brush,
    required this.mode,
    required this.onBrushChanged,
  });

  final MeetingAnswer brush;
  final MeetingMode mode;
  final ValueChanged<MeetingAnswer> onBrushChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MeetingBrushPicker(value: brush, onChanged: onBrushChanged),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            keepWords(meetingBrushLine(brush, mode)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
