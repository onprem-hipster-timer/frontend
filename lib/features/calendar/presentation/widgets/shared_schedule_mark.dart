import 'package:material_ui/material_ui.dart';

/// 공유받은 일정 블록의 제목 앞 표시. 스크린 리더는 '공유받은 일정'으로 읽는다
class SharedScheduleMark extends StatelessWidget {
  const SharedScheduleMark({super.key, required this.color, this.size = 12});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Icon(
        Icons.people_outline,
        size: size,
        color: color,
        semanticLabel: '공유받은 일정',
      ),
    );
  }
}
