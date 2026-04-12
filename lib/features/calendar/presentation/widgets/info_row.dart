import 'package:flutter/material.dart';

/// 아이콘 + 라벨 + 값을 한 행에 표시하는 범용 위젯.
///
/// [isMultiline]이 true이면 라벨과 값이 세로로 배치됩니다.
/// [valueWidget]이 제공되면 [value] 텍스트 대신 위젯을 표시합니다.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? valueWidget;
  final bool isMultiline;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueWidget,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.titleSmall?.copyWith(
      color: Colors.grey[600],
      fontWeight: FontWeight.w500,
    );

    if (isMultiline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Text(label, style: labelStyle),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child:
                valueWidget ?? Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        SizedBox(width: 60, child: Text(label, style: labelStyle)),
        const SizedBox(width: 12),
        Expanded(
          child: valueWidget ?? Text(value, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
