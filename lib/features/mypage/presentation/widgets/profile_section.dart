import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:momeet/features/mypage/presentation/providers/my_page_providers.dart';

/// 마이페이지 프로필 섹션
class ProfileSection extends ConsumerWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Card(
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
              child: profileAsync.when(
                data: (profile) => profile != null
                    ? _ProfileLines(
                        title: profile.email,
                        subtitle:
                            '가입일: ${DateFormat('yyyy년 M월 d일', 'ko').format(profile.createdAt)}',
                      )
                    : const _ProfileLines(
                        title: '사용자 정보 없음',
                        subtitle: '로그인이 필요합니다',
                      ),
                loading: () => const _ProfileSkeleton(),
                error: (error, stack) => _ProfileLoadError(
                  onRetry: () => ref.invalidate(userProfileProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 굵은 제목 줄과 흐린 설명 줄
class _ProfileLines extends StatelessWidget {
  const _ProfileLines({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 불러오는 동안 두 줄 자리를 채우는 회색 막대
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.smAll,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 16,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.smAll,
          ),
        ),
      ],
    );
  }
}

/// 불러오지 못했다는 줄과 다시 시도
class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 16),
            const SizedBox(width: 4),
            Text(
              '데이터를 불러올 수 없습니다',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onRetry,
          child: Row(
            children: [
              Icon(Icons.refresh, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                '다시 시도',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
