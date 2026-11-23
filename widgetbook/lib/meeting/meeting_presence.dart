import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_adjustment.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_adjustment_notice.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_presence.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_question_prompt.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_c.dart';

@widgetbook.UseCase(name: '펼치며 나타나기', type: MeetingPresence, path: '[모임]/화면 틀')
Widget meetingPresence(BuildContext context) {
  final reduce = context.knobs.boolean(
    label: '애니메이션 줄이기',
    description: meetingReduceMotionDescription,
  );
  return meetingMotionSetting(
    context,
    reduce: reduce,
    child: meetingCreateFrame(const _Notice()),
  );
}

/// 앱처럼 질문 위의 '묻지 않고 맞춘 것' 알림을 보였다 숨긴다
class _Notice extends StatefulWidget {
  const _Notice();

  @override
  State<_Notice> createState() => _NoticeState();
}

class _NoticeState extends State<_Notice> {
  var _shown = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _shown = !_shown),
            icon: Icon(_shown ? Icons.unfold_less : Icons.unfold_more),
            label: Text(_shown ? '숨기기' : '보이기'),
          ),
        ),
        const SizedBox(height: 16),
        MeetingPresence(
          child: _shown
              ? const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: MeetingAdjustmentNotice(
                    adjusted: {MeetingAdjustment.exclusionsDropped},
                    draft: MeetingDraft(),
                  ),
                )
              : null,
        ),
        const MeetingQuestionPrompt(
          headline: meetingExclusionQuestion,
          guide: meetingExclusionGuide,
        ),
      ],
    );
  }
}
