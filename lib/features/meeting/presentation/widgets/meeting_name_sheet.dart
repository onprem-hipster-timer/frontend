import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_sheet_view.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 이 모임에서 보일 내 이름을 바꾸는 시트를 연다
Future<void> showMeetingNameSheet(
  BuildContext context, {
  required String meetingId,
  required String currentName,
}) => showAppSheet<void>(
  context,
  builder: (context) =>
      MeetingNameSheet(meetingId: meetingId, currentName: currentName),
);

/// 이 모임에서 보일 내 이름 입력
class MeetingNameSheet extends ConsumerStatefulWidget {
  const MeetingNameSheet({
    super.key,
    required this.meetingId,
    required this.currentName,
  });

  final String meetingId;
  final String currentName;

  @override
  ConsumerState<MeetingNameSheet> createState() => _MeetingNameSheetState();
}

class _MeetingNameSheetState extends ConsumerState<MeetingNameSheet> {
  Future<void> _submit(String name) async {
    if (ref.read(renameInMeetingMutation).isPending) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await renameInMeetingMutation.run(
        ref,
        (tsx) => tsx
            .get(meetingBoardProvider(widget.meetingId).notifier)
            .rename(name),
      );
      navigator.pop();
      messenger.showAppSnackBar('닉네임을 바꿨습니다', kind: AppNoticeKind.success);
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          '닉네임을 바꾸지 못했습니다: $error',
          kind: AppNoticeKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MeetingNameSheetView(
      currentName: widget.currentName,
      busy: ref.watch(renameInMeetingMutation).isPending,
      onSubmit: _submit,
    );
  }
}
