import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_brush_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_edit_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_field_refusal.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_title_field.dart';

/// 모임 설정 폼의 끝: 제목 칸, 저장 전 알림([notices]), 저장하지 못한 까닭([outcome]), 저장하기.
/// [onSave]가 null이면(바꾼 것이 없으면) 저장하기를 누를 수 없다
class MeetingEditActions extends StatelessWidget {
  const MeetingEditActions({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.notices,
    required this.saving,
    required this.onSave,
    this.titleRefusal,
    this.outcome,
  });

  final TextEditingController controller;

  /// 제목을 비우면 쓰는 제목
  final String placeholder;

  /// 참여자가 이미 답을 넣었을 때 저장 전에 알리는 줄
  final List<String> notices;

  /// 저장하는 중이면 진행 표시를 두고 누를 수 없다
  final bool saving;

  final VoidCallback? onSave;

  /// 서버가 제목을 거절한 까닭
  final String? titleRefusal;

  /// 저장하지 못한 것이 있으면 무엇을 저장했고 무엇을 못 했는지
  final String? outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSave = this.onSave;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: meetingEditTitleLabel,
            hintText: placeholder,
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(MeetingTitleField.maxLength),
          ],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSave?.call(),
        ),
        if (titleRefusal case final text?) MeetingFieldRefusal(text),
        for (final notice in notices)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    keepWords(notice),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (outcome case final text?) MeetingFieldRefusal(text),
        const SizedBox(height: 20),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton(
            onPressed: saving ? null : onSave,
            style: FilledButton.styleFrom(minimumSize: const Size(120, 52)),
            child: saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: '저장하는 중',
                    ),
                  )
                : const Text(meetingEditSave),
          ),
        ),
      ],
    );
  }
}
