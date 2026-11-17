import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 내 답을 지우기 전에 한 번 묻는다. [question]은 무엇을 지우는지다('11월 23일에 표시한 시간을 모두 지울까요?').
/// [wide]면 대화상자, 아니면 하단 시트다. '초기화하기'를 고르면 true, 취소하거나 닫으면 false
Future<bool> askResetMeetingAnswers(
  BuildContext context, {
  required String question,
  required bool wide,
}) async {
  const title = '일정 초기화';
  const confirm = '초기화하기';
  if (wide) {
    return showAppConfirmDialog(
      context,
      title: title,
      content: question,
      confirmText: confirm,
      destructive: true,
    );
  }
  final chosen = await showAppSheet<bool>(
    context,
    animationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (context) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      return SafeArea(
        top: false,
        // 낮은 화면·큰 글자에서는 시트 안에서 굴린다
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(question, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                child: const Text(confirm),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('취소'),
              ),
            ],
          ),
        ),
      );
    },
  );
  return chosen ?? false;
}
