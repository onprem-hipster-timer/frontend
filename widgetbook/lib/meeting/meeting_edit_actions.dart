import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_edit.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_edit_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_edit_actions.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '모임 설정 제목과 저장하기',
  type: MeetingEditActions,
  path: '[모임]/모임 만들기',
)
Widget meetingEditActions(BuildContext context) {
  final knobs = context.knobs;
  final changed = knobs.boolean(
    label: '바꾼 것 있음',
    initialValue: true,
    description: '바꾼 것이 없으면 저장하기를 누를 수 없다',
  );
  final saving = knobs.boolean(label: '저장하는 중');
  final notices = knobs.object.dropdown(
    label: '저장 전 알림',
    description: '참여자가 이미 답을 넣은 모임에서 방식이나 날짜를 바꿀 때',
    options: const ['없음', '한 줄', '두 줄'],
  );
  final titleRefused = knobs.boolean(label: '제목 거절됨');
  final partly = knobs.boolean(
    label: '일부 저장 못 함',
    description: '여러 설정 중 일부만 저장되었을 때 저장하기 위에 알린다',
  );
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: _TitleHost(
      builder: (controller) => MeetingEditActions(
        controller: controller,
        placeholder: '모모님의 모임 일정',
        notices: [
          if (notices != '없음')
            meetingEditNoticeText(MeetingEditNotice.modeChanged),
          if (notices == '두 줄')
            meetingEditNoticeText(MeetingEditNotice.daysDropped),
        ],
        saving: saving,
        onSave: changed ? () {} : null,
        titleRefusal: titleRefused
            ? meetingEditRefusalText(MeetingEditPart.title)
            : null,
        outcome: partly ? '제목은 저장했어요. 공개 범위는 저장하지 못했어요. 잠시 뒤 다시 시도해 주세요' : null,
      ),
    ),
  );
}

/// 제목 칸의 controller를 쥔다
class _TitleHost extends StatefulWidget {
  const _TitleHost({required this.builder});

  final Widget Function(TextEditingController controller) builder;

  @override
  State<_TitleHost> createState() => _TitleHostState();
}

class _TitleHostState extends State<_TitleHost> {
  final _controller = TextEditingController(text: '3월 스터디 모임');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}
