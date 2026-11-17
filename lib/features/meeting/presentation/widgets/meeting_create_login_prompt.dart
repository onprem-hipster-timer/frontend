import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 로그인하지 않은 사람이 모임을 만들려 할 때 까닭과 함께 로그인을 묻는다. [wide]면 대화상자, 아니면 하단 시트다.
/// '로그인하고 계속하기'를 고르면 true, 닫으면 false
Future<bool> askLoginToCreateMeeting(
  BuildContext context, {
  required bool wide,
}) async {
  final reason = '${Terms.meeting.withJosa('을', '를')} 만들고 나중에 고치려면 로그인이 필요해요';
  const reassurance = '입력한 내용은 그대로 남아요';
  const login = '로그인하고 계속하기';
  if (wide) {
    final chosen = await showAppDialog<bool>(
      context,
      builder: (context) => AlertDialog(
        title: Text(reason),
        content: const Text(reassurance),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(login),
          ),
        ],
      ),
    );
    return chosen ?? false;
  }
  final chosen = await showAppSheet<bool>(
    context,
    animationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        top: false,
        // 낮은 화면·큰 글자에서는 시트 안에서 굴린다
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                reason,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reassurance,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text(login),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('닫기'),
              ),
            ],
          ),
        ),
      );
    },
  );
  return chosen ?? false;
}
