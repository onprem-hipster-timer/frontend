import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_edit_texts.dart';

/// 모임 화면 머리띠의 제목. [onEdit]이 있으면(주인) 제목 옆에 모임 설정을 여는 연필을 둔다
class MeetingPageTitle extends StatelessWidget {
  const MeetingPageTitle(this.title, {super.key, this.onEdit});

  final String title;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final onEdit = this.onEdit;
    if (onEdit == null) return Text(title);
    return Row(
      children: [
        Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 4),
        IconButton(
          onPressed: onEdit,
          tooltip: meetingEditTitle,
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    );
  }
}
