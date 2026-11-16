import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_names.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/shared/domain/terms.dart';
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
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(renameInMeetingMutation).isPending) return;
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await renameInMeetingMutation.run(
        ref,
        (tsx) => tsx
            .get(meetingBoardProvider(widget.meetingId).notifier)
            .rename(_name.text),
      );
      navigator.pop();
      messenger.showAppSnackBar('이름을 바꿨습니다', kind: AppNoticeKind.success);
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          '이름을 바꾸지 못했습니다: $error',
          kind: AppNoticeKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: '내 이름',
      formKey: _formKey,
      actions: AppFormActionBar(
        submitLabel: '저장',
        onSubmit: _submit,
        busy: ref.watch(renameInMeetingMutation).isPending,
      ),
      children: [
        TextFormField(
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '이 ${Terms.meeting}에서 보일 이름',
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          validator: (value) => meetingNameError(value ?? ''),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}
