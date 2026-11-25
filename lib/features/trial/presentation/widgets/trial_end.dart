import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/auth.dart' show AuthSwitchPrompt;
import 'package:momeet/features/todo/todo.dart'
    show TodoElapsedBadgeView, TodoTagIndicators, TodoTreeTileView;
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 체험하기의 끝. 할 일 줄(읽기만: 상태 아이콘·누적 집중 시간·태그, [TodoTreeTileView]), 가입하기([onSignUp])를
/// 두고, 구분선 아래에 모임 만들기 줄([onCreateMeeting])을 글과 글자 버튼으로 낮춰 둔다
class TrialEnd extends StatelessWidget {
  const TrialEnd({
    super.key,
    required this.todo,
    required this.recordedSeconds,
    required this.onSignUp,
    required this.onCreateMeeting,
  });

  final TodoRead todo;
  final int recordedSeconds;
  final VoidCallback onSignUp;
  final VoidCallback onCreateMeeting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card.outlined(
          child: TodoTreeTileView(
            todo: todo,
            meta: [
              TodoElapsedBadgeView(finishedSeconds: recordedSeconds),
              if (todo.tags.isNotEmpty) TodoTagIndicators(tags: todo.tags),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: onSignUp, child: const Text(trialSignUp)),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        AuthSwitchPrompt(
          question: trialMeetingLead,
          actionLabel: trialMeetingAction,
          onPressed: onCreateMeeting,
        ),
      ],
    );
  }
}
