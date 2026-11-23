import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_date_badge.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '모임 첫날 달력', type: MeetingDateBadge, path: '[모임]')
Widget meetingDateBadge(BuildContext context) {
  final day = context.knobs.dateTimeOrNull(
    label: '첫날',
    description: '비우면 날짜를 아직 모르는 상태',
    initialValue: DateTime(2027, 3, 2),
    start: DateTime(2027),
    end: DateTime(2028),
  );
  return Center(child: MeetingDateBadge(day: day));
}
