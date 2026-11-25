import 'package:material_ui/material_ui.dart';

/// 동의 항목 하나. [onOpenLink]를 주면 옆에 '보기'를 둔다. [emphasized]는 '전체 동의'처럼 굵게 쓴다
class ConsentCheckTileView extends StatelessWidget {
  const ConsentCheckTileView({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onOpenLink,
    this.description,
    this.emphasized = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// '보기'를 누르면 부른다
  final VoidCallback? onOpenLink;
  final String? description;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final onOpenLink = this.onOpenLink;
    final description = this.description;
    final onChanged = this.onChanged;
    return CheckboxListTile(
      value: value,
      onChanged: onChanged == null
          ? null
          : (checked) => onChanged(checked ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        label,
        style: emphasized
            ? Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            : null,
      ),
      subtitle: description == null ? null : Text(description),
      secondary: onOpenLink == null
          ? null
          : TextButton(
              onPressed: onOpenLink,
              // 항목 글자가 쓸 폭을 남기도록 기본 최소 폭(64) 대신 터치 영역(48)만 둔다
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('보기'),
            ),
    );
  }
}
