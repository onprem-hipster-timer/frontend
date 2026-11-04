import 'package:flutter/material.dart';

/// 선택지 하나
class DialogChoice<T> {
  const DialogChoice({
    required this.value,
    required this.label,
    this.description,
  });

  final T value;
  final String label;
  final String? description;
}

/// 선택지 중 하나를 고르는 다이얼로그. 닫으면 null.
///
/// 서버가 기본값 없이 클라이언트의 결정을 요구하는 정책(연결 일정·원본 할 일 처리)을 물을 때 쓴다.
Future<T?> showChoiceDialog<T>(
  BuildContext context, {
  required String title,
  required String content,
  required List<DialogChoice<T>> choices,
}) {
  return showDialog<T>(
    context: context,
    useRootNavigator: true,
    builder: (context) => SimpleDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      children: [
        Text(content),
        const SizedBox(height: 16),
        for (final choice in choices)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(choice.label),
            subtitle: choice.description == null
                ? null
                : Text(choice.description!),
            onTap: () => Navigator.of(context).pop(choice.value),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ),
      ],
    ),
  );
}
