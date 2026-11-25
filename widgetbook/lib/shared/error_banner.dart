import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/widgets/error_banner.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '오류 배너', type: ErrorBanner, path: '[공통]/상태 안내')
Widget errorBanner(BuildContext context) {
  final knobs = context.knobs;
  final message = knobs.stringOrNull(
    label: '메시지',
    description: '비우면 배너가 접히며 사라진다',
    initialValue: '연결 요청이 만료되었거나 올바르지 않습니다. Google로 다시 로그인해주세요.',
  );
  final dismiss = knobs.boolean(label: '닫기 버튼', initialValue: true);
  return Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: ErrorBanner(message: message, onDismiss: dismiss ? () {} : null),
    ),
  );
}
