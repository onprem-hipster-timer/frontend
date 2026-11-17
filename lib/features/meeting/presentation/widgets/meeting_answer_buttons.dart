import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 답 하나: 글자와 누를 때 할 일
typedef MeetingAnswer = ({String label, VoidCallback onPressed});

/// 질문의 답 단추들. 모두 같은 모양이라 미리 고른 답이 없고, 다시 묻는 질문이면 지금 답([selected])만 채운다.
/// 누른 답은 바로 채워 다음 질문으로 넘어가는 동안 고른 모양으로 보인다. 한 줄에 들어가면 같은 폭으로 나란히,
/// 아니면 위아래로 쌓는다
class MeetingAnswerButtons extends StatefulWidget {
  const MeetingAnswerButtons({super.key, required this.answers, this.selected});

  final List<MeetingAnswer> answers;

  /// 지금 답의 글자(다시 묻는 질문)
  final String? selected;

  static const _gap = 12.0;
  static const _height = 52.0;

  @override
  State<MeetingAnswerButtons> createState() => _MeetingAnswerButtonsState();
}

class _MeetingAnswerButtonsState extends State<MeetingAnswerButtons> {
  /// 방금 누른 답의 글자
  String? _pressed;

  @override
  Widget build(BuildContext context) {
    final MeetingAnswerButtons(:answers, :selected) = widget;
    const gap = MeetingAnswerButtons._gap;
    final style = Theme.of(context).textTheme.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final widest = answers
            .map((answer) => _widthOf(answer.label, style, scaler))
            .fold(0.0, math.max);
        final row =
            (widest + 48) * answers.length + gap * (answers.length - 1) <=
            constraints.maxWidth;
        final buttons = [
          for (final answer in answers)
            _AnswerButton(
              answer: answer,
              chosen: answer.label == (_pressed ?? selected),
              onPressed: () {
                setState(() => _pressed = answer.label);
                answer.onPressed();
              },
            ),
        ];
        if (row) {
          return Row(
            children: [
              for (final (i, button) in buttons.indexed) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(child: button),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, button) in buttons.indexed) ...[
              if (i > 0) const SizedBox(height: 8),
              button,
            ],
          ],
        );
      },
    );
  }

  static double _widthOf(String text, TextStyle? style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.answer,
    required this.chosen,
    required this.onPressed,
  });

  final MeetingAnswer answer;
  final bool chosen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size(0, MeetingAnswerButtons._height),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
    );
    // 단추가 글자의 시맨틱스를 합치므로 고른 상태는 글자에 단다
    final label = Semantics(
      selected: chosen ? true : null,
      child: Text(answer.label, textAlign: TextAlign.center),
    );
    return chosen
        ? FilledButton(onPressed: onPressed, style: style, child: label)
        : FilledButton.tonal(onPressed: onPressed, style: style, child: label);
  }
}
