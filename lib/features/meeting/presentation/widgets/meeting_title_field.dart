import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 제목과 만들기 화살표. 제목을 비우면 [placeholder]로 만든다
class MeetingTitleField extends StatelessWidget {
  const MeetingTitleField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.submitting,
    required this.onSubmit,
  });

  /// backend 제목 상한
  static const maxLength = 200;

  final TextEditingController controller;
  final String placeholder;

  /// 만드는 중이면 화살표 대신 진행 표시를 두고 누를 수 없다
  final bool submitting;

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: placeholder),
            inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: submitting ? null : onSubmit,
          tooltip: '${Terms.meeting} 만들기',
          style: IconButton.styleFrom(
            minimumSize: const Size(64, 56),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          ),
          icon: submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward),
        ),
      ],
    );
  }
}
