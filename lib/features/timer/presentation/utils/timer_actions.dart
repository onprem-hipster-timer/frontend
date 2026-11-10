import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

const _stopTimerConfirmTitle = '작업 완료';
const _stopTimerConfirmContent =
    '작업을 완료하시겠습니까?\n완료한 타이머는 다시 시작할 수 없습니다.\n잠시 멈추려면 일시정지를 이용해 주세요.';

/// 타이머 완료 확인 다이얼로그. 사용자가 완료를 확인하면 true.
Future<bool> confirmStopTimer(BuildContext context) {
  return showAppConfirmDialog(
    context,
    title: _stopTimerConfirmTitle,
    content: _stopTimerConfirmContent,
    confirmText: '완료',
    destructive: true,
  );
}

/// 시간이 끝난 타이머를 한 번에 늘리는 시간
const timerExtendStep = Duration(minutes: 5);
