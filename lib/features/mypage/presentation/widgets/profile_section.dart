import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/mypage/presentation/providers/my_page_providers.dart';
import 'package:momeet/features/mypage/presentation/widgets/profile_section_view.dart';

/// 마이페이지 프로필 섹션
class ProfileSection extends ConsumerWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProfileSectionView(
      profile: ref.watch(userProfileProvider),
      onRetry: () => ref.invalidate(userProfileProvider),
    );
  }
}
