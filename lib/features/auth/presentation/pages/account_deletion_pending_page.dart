import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_button.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_heading.dart';

/// 탈퇴를 신청한 계정으로 다시 로그인했을 때. 파기 예정 시각을 알리고 취소하거나 로그아웃한다.
///
/// 취소하면 라우터가 원래 가려던 화면(약관 동의가 필요하면 동의 화면)으로 보낸다.
class AccountDeletionPendingPage extends ConsumerStatefulWidget {
  const AccountDeletionPendingPage({super.key});

  @override
  ConsumerState<AccountDeletionPendingPage> createState() =>
      _AccountDeletionPendingPageState();
}

class _AccountDeletionPendingPageState
    extends ConsumerState<AccountDeletionPendingPage> {
  static final _dateTimeFormat = DateFormat('yyyy년 M월 d일 HH:mm', 'ko');

  bool _cancelling = false;
  bool _signingOut = false;

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(myProfileProvider.notifier).cancelDeletion();
    } on Exception catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          '탈퇴 취소에 실패했습니다: $e',
          kind: AppNoticeKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await ref.read(authProvider.notifier).signOut();
    } on Exception catch (e) {
      if (mounted) {
        showAppSnackBar(context, '로그아웃 실패: $e', kind: AppNoticeKind.error);
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider);
    if (profile.hasError && !profile.isLoading) {
      return Scaffold(
        body: AppErrorState(
          title: '계정 정보를 불러오지 못했습니다',
          error: profile.error,
          onRetry: () => ref.invalidate(myProfileProvider),
          secondaryLabel: '로그아웃',
          secondaryIcon: Icons.logout,
          onSecondary: _signingOut ? null : _signOut,
        ),
      );
    }
    final scheduledAt = profile.value?.deletionScheduledAt;
    if (profile.isLoading || scheduledAt == null) {
      return const Scaffold(body: AppLoading());
    }
    final theme = Theme.of(context);
    final busy = _cancelling || _signingOut;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeading(
                title: '탈퇴를 신청한 계정입니다',
                subtitle: '탈퇴를 취소하면 지금까지처럼 이용할 수 있습니다',
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_dateTimeFormat.format(scheduledAt.toLocal())}에 '
                        '계정과 모든 데이터가 지워집니다.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '그 전에 취소하면 아무것도 지워지지 않습니다. '
                        '지워진 뒤에는 되돌릴 수 없습니다.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AuthButton(
                text: '탈퇴 취소하고 계속 이용',
                onPressed: busy ? null : _cancel,
                isLoading: _cancelling,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: busy ? null : _signOut,
                child: const Text('로그아웃'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
