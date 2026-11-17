import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_brush_texts.dart';
import 'package:momeet/shared/ui/ui.dart';

/// '안전한 정규 유저로 바꾸기'를 고른 게스트에게 무엇이 바뀌는지 알리고 묻는다. [wide]면 대화상자, 아니면 하단
/// 시트다. '로그인하고 옮기기'를 고르면 true, 취소하면 false
Future<bool> askGuestUpgrade(BuildContext context, {required bool wide}) async {
  const title = '안전한 정규 유저로 바꾸기';
  const what = '회원으로 로그인하면 게스트로 넣은 시간이 계정으로 옮겨지고, 게스트 닉네임은 사라져요';
  const why = '비밀번호를 잊어도 찾을 수 있고, 다른 기기에서도 이어서 쓸 수 있어요';
  const go = '로그인하고 옮기기';
  if (wide) {
    final chosen = await showAppDialog<bool>(
      context,
      builder: (context) => AlertDialog(
        title: const Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(keepWords(what)),
            const SizedBox(height: 8),
            Text(keepWords(why)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(go),
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
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(keepWords(what)),
              const SizedBox(height: 8),
              Text(
                keepWords(why),
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
                child: const Text(go),
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
