// 게스트 세션 안내
//
// 게스트는 자기 모임 화면에서만 머문다. 다른 화면으로 가면 라우터가 이 화면으로 보낸다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// '로그인이 필요합니다'. 회원으로 로그인하거나 게스트로 들어온 모임으로 돌아간다.
///
/// [redirect]는 가려던 곳이다. 회원으로 로그인하면 그리로 간다. 들어온 모임을 이 기기가 모르면 모임으로
/// 돌아가는 대신 게스트 세션을 끝내는 길을 둔다.
class GuestSessionPage extends ConsumerWidget {
  const GuestSessionPage({super.key, this.redirect});

  final String? redirect;

  Future<void> _endSession(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authProvider.notifier).signOut();
    } on Exception catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          '게스트 세션을 끝내지 못했습니다: $e',
          kind: AppNoticeKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final meetingId = ref.watch(
      currentGuestProvider.select((guest) => guest?.meetingId),
    );
    final redirect = this.redirect;
    return Scaffold(
      body: Center(
        // 낮은 화면·큰 글자에서는 굴린다
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_person_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                '로그인이 필요합니다',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '(게스트 세션에서는 해당 기능을 이용할 수 없습니다.)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.goNamed(
                  AppRoute.login.name,
                  queryParameters: {'redirect': ?redirect},
                ),
                icon: const Icon(Icons.login),
                label: const Text('회원으로 로그인'),
              ),
              const SizedBox(height: 12),
              if (meetingId != null)
                OutlinedButton.icon(
                  onPressed: () => context.goNamed(
                    AppRoute.meeting.name,
                    pathParameters: {'meetingId': meetingId},
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: Text('${Terms.meeting.withJosa('으로', '로')} 돌아가기'),
                )
              else
                TextButton(
                  onPressed: () => _endSession(context, ref),
                  child: const Text('게스트 세션 끝내기'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
