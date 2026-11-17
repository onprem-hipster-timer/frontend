import 'package:material_ui/material_ui.dart';

/// 허용 / 비허용 둘 중 하나
class MeetingChoiceRow extends StatelessWidget {
  const MeetingChoiceRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  /// 스크린 리더가 함께 읽는 이름 (예: '공개 여부')
  final String label;

  /// 허용이면 true
  final bool value;

  /// null이면 고를 수 없다
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Semantics(
      label: label,
      container: true,
      child: RadioGroup<bool>(
        groupValue: value,
        onChanged: (value) {
          if (value != null) onChanged?.call(value);
        },
        child: Wrap(
          spacing: 12,
          children: [
            for (final (option, text) in const [(true, '허용'), (false, '비허용')])
              _Option(
                value: option,
                text: text,
                onSelect: onChanged == null ? null : () => onChanged(option),
              ),
          ],
        ),
      ),
    );
  }
}

/// 라디오와 글자. 글자를 눌러도 고른다
class _Option extends StatelessWidget {
  const _Option({
    required this.value,
    required this.text,
    required this.onSelect,
  });

  final bool value;
  final String text;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onSelect != null;
    return MergeSemantics(
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<bool>(value: value, enabled: enabled),
              Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: enabled
                      ? null
                      : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
