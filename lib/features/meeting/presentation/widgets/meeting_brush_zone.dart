import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_brush_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_brush_picker.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_shake.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 칠하기 조작 영역: 붓 고르기, 날짜별·요일별의 '일정 초기화하기'([onClearAll]), 고른 붓으로 무엇을 칠하는지 한 줄
/// ([meetingBrushLine]). 붓 안내는 격자 전체에 대한 말이라 붓 옆에 두고, 붓을 바꾸면 스크린 리더가 읽는다.
/// [shakes]가 바뀌면 붓 줄을 떤다(다른 방식으로 표시한 모임에 칠하려 했을 때).
class MeetingBrushZone extends StatelessWidget {
  const MeetingBrushZone({
    super.key,
    required this.brush,
    required this.mode,
    required this.onBrushChanged,
    this.onClearAll,
    this.shakes = 0,
  });

  final MeetingAnswer brush;
  final MeetingMode mode;
  final ValueChanged<MeetingAnswer> onBrushChanged;

  /// 내 답을 모두 지운다. 지울 답이 없으면 null(누를 수 없다). 시간별은 날짜 머리가 하루씩 지워서 두지 않는다
  final VoidCallback? onClearAll;
  final int shakes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MeetingShake(
          count: shakes,
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MeetingBrushPicker(value: brush, onChanged: onBrushChanged),
              if (mode != MeetingMode.hourly)
                TextButton.icon(
                  onPressed: onClearAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('일정 초기화하기'),
                ),
            ],
          ),
        ),
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
