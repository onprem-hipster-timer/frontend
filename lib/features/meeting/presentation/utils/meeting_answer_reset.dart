import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_shading.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/shared/ui/ui.dart';

/// [cells]의 내 답을 지우고 [done]과 되돌리기 알림을 띄운다. 되돌리면 지우기 전 답으로 다시 칠한다
Future<void> resetMeetingAnswers(
  ScaffoldMessengerState messenger, {
  required MeetingShading shading,
  required Iterable<MeetingCell> cells,
  required MeetingPaint onPaint,
  required String done,
}) async {
  final before = {
    for (final cell in cells)
      if (shading.answerAt(cell) != MeetingAnswer.unanswered)
        cell: shading.answerAt(cell),
  };
  if (before.isEmpty) return;
  onPaint({for (final cell in before.keys) cell: MeetingAnswer.unanswered});
  if (await messenger.showAppUndoSnackBar(done)) onPaint(before);
}
