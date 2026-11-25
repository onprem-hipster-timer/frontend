import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_crown.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '주인 왕관', type: MeetingCrown, path: '[모임]/참여자')
Widget meetingCrown(BuildContext context) {
  final size = context.knobs.double.slider(
    label: '크기',
    description: '참여자 이름 칩 안에서는 글자 크기에 맞춰 16 안팎이다',
    initialValue: 16,
    min: 12,
    max: 64,
    divisions: 13,
    precision: 0,
  );
  return Center(child: MeetingCrown(size: size));
}
