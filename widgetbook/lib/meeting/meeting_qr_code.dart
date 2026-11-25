import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_qr_code.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '모임 링크 QR 코드',
  type: MeetingQrCode,
  path: '[모임]/모임 만들기',
)
Widget meetingQrCode(BuildContext context) {
  final knobs = context.knobs;
  final link = knobs.string(
    label: '링크',
    initialValue:
        'https://momeet.example/meetings/3f2a9c1e-7b4d-4e8a-9c21-5d6f0a1b2c3d',
  );
  final size = knobs.double.slider(
    label: '크기',
    description: '자리가 이보다 좁으면 그 폭에 맞춰 줄어든다',
    initialValue: 200,
    min: 120,
    max: 400,
    divisions: 28,
    precision: 0,
  );
  // 앱에서는 모임을 만든 뒤 화면의 폭 360 칸 가운데, 링크 줄 위에 놓인다
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: MeetingQrCode(data: link, size: size),
      ),
    ),
  );
}
