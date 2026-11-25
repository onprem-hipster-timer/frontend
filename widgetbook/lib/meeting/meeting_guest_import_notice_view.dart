import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_guest_import_phase.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_import_notice_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _phases = {
  '옮기는 중': MeetingGuestImportPhase.importing,
  '옮기지 못함': MeetingGuestImportPhase.failed,
};

@widgetbook.UseCase(
  name: '게스트 시간 옮기기 안내',
  type: MeetingGuestImportNoticeView,
  path: '[모임]/들어오기·계정',
)
Widget meetingGuestImportNoticeView(BuildContext context) {
  final phase = context.knobs.object.dropdown(
    label: '상태',
    options: _phases.keys.toList(),
    description:
        '게스트로 시간을 넣다가 로그인하면 회원의 모임 화면 맨 위에서 그 시간을 계정으로 옮긴다. '
        "옮기지 못하면 '다시 시도'를 둔다. 옮기면 줄이 사라지고 알림이 뜬다",
  );
  // 앱에서는 회원의 모임 화면에서 시간표 바로 위에 놓인다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: MeetingGuestImportNoticeView(phase: _phases[phase], onRetry: () {}),
  );
}
