import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_request_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../sample_provider_scope.dart';
import '../shared/samples_shared.dart';
import 'samples_guest_form.dart';

@widgetbook.UseCase(
  name: '내 시간 입력하기 시트',
  type: MeetingLoginRequestView,
  path: '[모임]/들어오기·계정',
)
Widget meetingLoginRequestView(BuildContext context) {
  final knobs = context.knobs;
  final guests = knobs.boolean(
    label: '게스트 받기',
    initialValue: true,
    description: "게스트를 받는 모임이면 '로그인' 옆에 'Guest'와 그 안내를 둔다",
  );
  final guestOpen = knobs.boolean(
    label: '게스트 폼 펼침',
    description:
        "'Guest'를 누르면 시트 안에서 게스트 폼으로 바뀌고 '뒤로'로 돌아간다. 폼의 상태는 '게스트 폼'에서 고른다",
  );
  // 앱에서는 좁은 화면의 방문자가 시간표를 칠하려 하거나 아래의 '내 시간 입력하기'를 누르면 아래에서
  // 올라온다. '로그인'을 누르면 닫고 로그인 화면으로 간다
  return SampleProviderScope(
    key: ValueKey((guests, guestOpen)),
    overrides: guestEntryOverrides,
    child: SheetPreview(
      child: _Request(guests: guests, guestOpen: guestOpen),
    ),
  );
}

/// 'Guest'로 폼을 열고 '뒤로'로 돌아가도록 펼침 상태를 여기서 가진다
class _Request extends StatefulWidget {
  const _Request({required this.guests, required this.guestOpen});

  final bool guests;
  final bool guestOpen;

  @override
  State<_Request> createState() => _RequestState();
}

class _RequestState extends State<_Request> {
  late var _open = widget.guestOpen;

  @override
  Widget build(BuildContext context) {
    final guests = widget.guests;
    return MeetingLoginRequestView(
      guestForm: guests && _open ? const SampleGuestForm() : null,
      onBack: () => setState(() => _open = false),
      onLogin: () => Navigator.of(context).pop(),
      onGuest: guests ? () => setState(() => _open = true) : null,
    );
  }
}
