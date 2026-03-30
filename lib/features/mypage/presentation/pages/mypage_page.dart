import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/shared/widgets/confirm_dialog.dart';
import 'package:momeet/shared/widgets/error_banner.dart';
import 'package:momeet/features/mypage/presentation/widgets/profile_section.dart';
import 'package:momeet/features/mypage/presentation/widgets/activity_stats_section.dart';
import 'package:momeet/features/mypage/presentation/widgets/tag_stats_section.dart';
import 'package:momeet/features/mypage/presentation/widgets/settings_section.dart';

class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
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
          const ProfileSection(),

          const SizedBox(height: 32),

          // 2. 활동 통계 섹션
          const ActivityStatsSection(),

          const SizedBox(height: 32),

          // 3. 태그 사용 통계 섹션
          const TagStatsSection(),

          const SizedBox(height: 32),

          // 4. 설정 섹션
          SettingsSection(onSignOut: _confirmSignOut),
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
