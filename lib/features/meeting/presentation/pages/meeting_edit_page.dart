import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_edit_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_edit_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_edit_form.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_glass_scaffold.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_not_found.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 설정 화면(`/meetings/<id>/edit`). 탭 셸 밖에 있고, 모임 화면 제목 옆 연필로 연다.
///
/// 주인만 고친다([MeetingEditForm]). 주인이 아니거나 없는 모임이면 모임 화면과 같은 '찾을 수 없음'이다.
/// 로그인하지 않았으면 로그인으로, 게스트는 자기 모임 화면 밖이라 게스트 안내로 간다(라우터).
class MeetingEditPage extends ConsumerWidget {
  const MeetingEditPage({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = meetingEditSourceProvider(meetingId);
    return MeetingGlassScaffold(
      title: const Text(meetingEditTitle),
      body: ref
          .watch(provider)
          .when(
            data: (source) => source == null
                ? const MeetingNotFound()
                : MeetingEditForm(source: source),
            loading: () => const AppLoading(),
            error: (error, _) => isMeetingNotFound(error)
                ? const MeetingNotFound()
                : AppErrorState(
                    title: meetingEditLoadFailed,
                    error: error,
                    onRetry: () => ref.invalidate(provider),
                  ),
          ),
    );
  }
}
