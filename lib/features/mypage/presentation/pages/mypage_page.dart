import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/shared/widgets/confirm_dialog.dart';
import 'package:momeet/shared/widgets/error_banner.dart';

class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // 프로필 섹션
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.email ?? '',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          ErrorBanner(
            message: _errorMessage,
            onDismiss: () => setState(() => _errorMessage = null),
          ),

          // 로그아웃 버튼
          FilledButton.tonal(
            onPressed: _confirmSignOut,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '로그아웃',
      content: '정말 로그아웃하시겠습니까?',
      confirmText: '로그아웃',
    );

    if (!confirmed) return;
    if (!mounted) return;

    try {
      await ref.read(authProvider.notifier).signOut();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '로그아웃 실패: $e');
    }
  }
}
