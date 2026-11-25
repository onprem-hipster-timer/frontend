import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/mypage/presentation/widgets/my_meetings_section_view.dart';

/// 마이페이지 '내 모임'. 내가 만든 모임을 불러와 [MyMeetingsSectionView]로 보인다
class MyMeetingsSection extends ConsumerWidget {
  const MyMeetingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MyMeetingsSectionView(
      meetings: ref.watch(myMeetingsProvider),
      onRetry: () => ref.invalidate(myMeetingsProvider),
    );
  }
}
