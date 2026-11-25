import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_form_view.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../sample_provider_scope.dart';
import 'samples_guest_form.dart';
import 'samples_turnstile.dart';

/// 폼 아래에 뜨는 거절 안내
const _messages = <String, String?>{
  '없음': null,
  '게스트를 받지 않음': '지금은 이 모임에 게스트로 들어갈 수 없습니다',
  '게스트 100명': '이 모임은 게스트가 100명이라 더 들어올 수 없습니다',
  '확인 실패': '사람인지 확인하지 못했습니다. 다시 시도해 주세요',
  '연결 끊김': '네트워크 연결을 확인해 주세요',
};

@widgetbook.UseCase(
  name: '게스트 폼',
  type: MeetingGuestFormView,
  path: '[모임]/들어오기·계정',
)
Widget meetingGuestFormView(BuildContext context) {
  final knobs = context.knobs;
  final nameState = knobs.object.dropdown(
    label: '닉네임',
    options: GuestNameState.values,
    labelBuilder: (state) => state.label,
    initialOption: GuestNameState.fresh,
    description:
        '닉네임 칸을 벗어나면 그 닉네임을 찾는다. 이미 참여한 닉네임이면 비밀번호로 들어가고, 처음 쓰는 '
        "닉네임이면 비밀번호를 바꾸거나 찾을 수 없다고 알리고 약관에 동의해야 '참여하기'를 누를 수 있다",
  );
  final turnstile = turnstileKnob(
    context,
    description: '사람 확인 상자(Cloudflare Turnstile) 상태',
  );
  final message = knobs.object.dropdown(
    label: '안내',
    options: _messages.keys.toList(),
    description: '들어가지 못하면 버튼 위에 까닭을 알린다',
  );
  final wrongPassword = knobs.boolean(
    label: '비밀번호가 맞지 않음',
    description: '이미 참여한 닉네임의 비밀번호가 틀리면 비밀번호 칸 아래에 알린다',
  );
  final busy = knobs.boolean(
    label: '들어가는 중',
    description: '누른 뒤 끝날 때까지 버튼에 진행 표시를 둔다',
  );
  // 앱에서는 넓은 화면 오른쪽 칸(380 폭)의 '게스트로 참여' 상자와 좁은 화면의 요청 시트 안에 놓인다. '보기'는
  // 약관 페이지를 새 탭으로 여는데, 카탈로그에서는 아무것도 열지 않는다. 노브를 바꾸면 입력한 값을 버린다
  return SampleProviderScope(
    overrides: [openLinkProvider.overrideWithValue((_) async {})],
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: MeetingPanel(
            title: '게스트로 참여',
            child: SampleGuestForm(
              key: ValueKey(nameState),
              nameState: nameState,
              turnstile: turnstile,
              message: _messages[message],
              passwordError: wrongPassword ? '비밀번호가 맞지 않습니다' : null,
              busy: busy,
            ),
          ),
        ),
      ),
    ),
  );
}
