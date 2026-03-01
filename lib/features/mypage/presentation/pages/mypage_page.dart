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
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          ErrorBanner(
            message: _errorMessage,
            onDismiss: () => setState(() => _errorMessage = null),
          ),

          // 1. 내 프로필 섹션
          _buildProfile(context, user?.email ?? 'gunyu1019@gmail.com'),

          const SizedBox(height: 32),

          // 2. 활동 통계 섹션
          _buildActivityStats(context),

          const SizedBox(height: 32),

          // 3. 태그 사용 통계 섹션
          _buildTagStats(context),

          const SizedBox(height: 32),

          // 4. 설정 섹션
          _buildSettings(context),
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context, String email) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
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
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '가입일: 2026년 2월 1일',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStats(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '활동 요약',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 전체 진행률
                Text(
                  '전체 진행률 (3개 완료 / 12개 전체)',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 3 / 12,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // 할 일 목록 통계
                Text(
                  '할 일 상태별 현황',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatusCard(context, '전체', '12', theme.colorScheme.primary)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatusCard(context, '미지정', '5', theme.colorScheme.secondary)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatusCard(context, '예정', '4', theme.colorScheme.tertiary)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatusCard(context, '완료', '3', Colors.green)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, String label, String count, Color color) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagStats(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '사용한 태그',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildTagChip(context, '업무', 8, Colors.blue),
                _buildTagChip(context, '개인', 5, Colors.purple),
                _buildTagChip(context, '운동', 3, Colors.orange),
                _buildTagChip(context, '공부', 7, Colors.green),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(BuildContext context, String tagName, int count, Color color) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tagName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '설정',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SwitchListTile(
                secondary: Icon(
                  Icons.dark_mode,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('다크 모드'),
                value: ref.watch(themeProvider.notifier).isDarkMode,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.language,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('타임존 설정'),
                trailing: Text(
                  'Asia/Seoul',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  // TODO: 타임존 설정 화면으로 이동
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('비밀번호 변경'),
                onTap: () {
                  // TODO: 비밀번호 변경 화면으로 이동
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                title: const Text(
                  '로그아웃',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _confirmSignOut,
              ),
            ],
          ),
        ),
      ],
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
