import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/auth.dart' show AuthSwitchPrompt;
import 'package:momeet/features/todo/todo.dart'
    show TodoElapsedBadgeView, TodoTagIndicators, TodoTreeTileView;
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 모임 화면 그림의 크기
const _previewSize = Size(180, 450);

/// 이 폭부터 모임 화면 그림을 모임 만들기 줄 옆에 둔다
const _sideBySideFrom = 480.0;

/// 체험하기의 끝. 할 일 줄(읽기만: 상태 아이콘·누적 집중 시간·태그, [TodoTreeTileView]), 가입하기([onSignUp])를
/// 두고, 구분선 아래에 모임 만들기 줄([onCreateMeeting])을 글과 글자 버튼으로 낮춰 둔다. 모임 화면 그림
/// ([meetingPreview])은 [_previewSize]로 그 줄 아래에, 넓으면 그 줄 옆에 둔다.
///
/// 테스트: test/features/trial/presentation/pages/trial_page_test.dart
class TrialEnd extends StatelessWidget {
  const TrialEnd({
    super.key,
    required this.todo,
    required this.recordedSeconds,
    required this.onSignUp,
    required this.onCreateMeeting,
    required this.meetingPreview,
  });

  final TodoRead todo;
  final int recordedSeconds;
  final VoidCallback onSignUp;
  final VoidCallback onCreateMeeting;

  /// 모임 만들기 줄과 함께 두는 모임 화면 그림
  final Widget meetingPreview;

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
        LayoutBuilder(
          builder: (context, constraints) {
            final prompt = AuthSwitchPrompt(
              question: trialMeetingLead,
              actionLabel: trialMeetingAction,
              onPressed: onCreateMeeting,
            );
            final preview = SizedBox.fromSize(
              size: _previewSize,
              child: meetingPreview,
            );
            if (constraints.maxWidth < _sideBySideFrom) {
              return Column(
                children: [prompt, const SizedBox(height: 16), preview],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: prompt),
                const SizedBox(width: 24),
                preview,
              ],
            );
          },
        ),
      ],
    );
  }
}
