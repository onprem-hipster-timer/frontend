import 'package:material_ui/material_ui.dart';

/// 폼·화면 안의 소제목. [trailing]을 주면 오른쪽 끝에 둔다(예: '새 태그' 버튼).
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
    final trailing = this.trailing;
    if (trailing == null) return text;
    return Row(
      children: [
        Expanded(child: text),
        trailing,
      ],
    );
  }
}
