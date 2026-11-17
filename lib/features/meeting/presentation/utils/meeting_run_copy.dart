import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 그 시간이 안 되는 사람 한 줄: '불가능 1명 · 다현'
String meetingUnavailableLine(List<String> names) =>
    '불가능 ${names.length}명 · ${names.join(', ')}';

/// 추천 시간 카드 한 장을 채팅에 붙여 넣을 글로 옮긴다. 첫 줄은 카드의 날짜와 시각(여러 날이면 괄호 안에 날
/// 수) · 되는 사람 수, 다음 줄은 되는 사람 이름([people], 카드 순서), 안 되는 사람([unavailable])이 있으면
/// 카드와 같은 '불가능' 줄이다.
///
/// 예: '3월 2일 (화) 10:00 ~ 12:00 · 2명', '3월 2일 ~ 3일 (2일) · 2명', '화요일 하루 종일 · 2명'
///
/// 테스트: test/features/meeting/presentation/widgets/meeting_slots_copy_test.dart
String meetingRunCopyText(
  MeetingGrid grid,
  MeetingRun run, {
  required List<String> people,
  required List<String> unavailable,
}) {
  final text = meetingRunText(grid, run);
  final days = grid.mode != MeetingMode.hourly && run.cells.length > 1;
  final when = days
      ? '${text.title} (${text.detail})'
      : '${text.title} ${text.detail}';
  return [
    '$when · ${people.length}명',
    if (people.isNotEmpty) people.join(', '),
    if (unavailable.isNotEmpty) meetingUnavailableLine(unavailable),
  ].join('\n');
}

/// [text]를 복사하고 [notice]로 알린다
Future<void> copyMeetingText(
  BuildContext context,
  String text, {
  required String notice,
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    showAppSnackBar(context, notice, kind: AppNoticeKind.success);
  }
}
