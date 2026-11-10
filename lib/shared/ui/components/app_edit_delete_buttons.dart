import 'package:material_ui/material_ui.dart';

/// 목록 줄 끝의 작은 '수정'·'삭제' 버튼 한 쌍. 삭제는 오류색이다.
///
/// 한 줄에 둘 다 들어가지 않으면 '삭제'를 다음 줄 오른쪽으로 꺾는다.
///
/// [itemName]을 주면 스크린 리더가 '<이름> 수정'처럼 무엇을 고치는지 함께 읽는다.
class AppEditDeleteButtons extends StatelessWidget {
  const AppEditDeleteButtons({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.itemName,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? itemName;

  /// 두 버튼이 차지하는 폭. 줄에 옆으로 둘지 정할 때 쓴다
  ///
  /// 버튼마다 안쪽 여백 20·아이콘 16·아이콘과 글자 사이 8에 글자 배율을 반영한 글자 폭을 더하고,
  /// 버튼 사이 8을 더한다.
  static double widthOf(BuildContext context) {
    final painter = TextPainter(
      text: const TextSpan(text: '수정', style: _labelStyle),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: TextDirection.ltr,
    )..layout();
    final label = painter.width;
    painter.dispose();
    return 2 * (44 + label) + 8;
  }

  static const _labelStyle = TextStyle(fontSize: 12);

  static final _style = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    minimumSize: const Size(0, 32),
    textStyle: _labelStyle,
  );

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final name = itemName;
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 4,
      children: [
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit, size: 16),
          label: Text('수정', semanticsLabel: name == null ? null : '$name 수정'),
          style: _style,
        ),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, size: 16),
          label: Text('삭제', semanticsLabel: name == null ? null : '$name 삭제'),
          style: _style.copyWith(
            foregroundColor: WidgetStatePropertyAll(error),
            side: WidgetStatePropertyAll(BorderSide(color: error)),
          ),
        ),
      ],
    );
  }
}
