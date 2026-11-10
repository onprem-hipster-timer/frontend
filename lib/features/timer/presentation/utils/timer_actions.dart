import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/timer/presentation/widgets/start_timer_sheet.dart';
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

/// 새 작업 시작 시트를 열고 고른 값으로 타이머를 시작한다
Future<void> startTimerFromSheet(
  BuildContext context,
  WidgetRef ref, {
  required Duration initialDuration,
}) async {
  final input = await showStartTimerSheet(
    context,
    initialDuration: initialDuration,
  );
  if (input == null || !context.mounted) return;
  final controller = ref.read(timerControllerProvider.notifier);
  if (input.todos.length >= 2) {
    final failed = await controller.startTimers(
      todos: input.todos,
      duration: input.duration,
    );
    if (!context.mounted) return;
    if (failed.isEmpty) {
      showAppSnackBar(context, '타이머를 시작했습니다');
    } else {
      showAppSnackBar(
        context,
        startFailureMessage(failed),
        kind: AppNoticeKind.error,
      );
    }
    return;
  }
  try {
    await controller.startTimer(
      relatedTodoId: input.todos.firstOrNull?.id,
      title: input.title,
      allocatedDurationSeconds: input.duration.inSeconds,
    );
    if (context.mounted) {
      showAppSnackBar(context, '타이머를 시작했습니다');
    }
  } catch (e) {
    if (context.mounted) {
      showAppSnackBar(context, '타이머 시작 실패: $e', kind: AppNoticeKind.error);
    }
  }
}
