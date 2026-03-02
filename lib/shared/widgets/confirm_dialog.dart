import 'package:flutter/material.dart';

/// 범용 확인 다이얼로그
///
/// ```dart
/// final confirmed = await showConfirmDialog(
///   context,
///   title: '로그아웃',
///   content: '정말 로그아웃하시겠습니까?',
///   confirmText: '로그아웃',
/// );
/// ```
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String cancelText;
  final String confirmText;
  final bool destructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelText = '취소',
    this.confirmText = '확인',
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// 확인 다이얼로그를 표시하고 사용자의 선택을 반환합니다.
///
/// [destructive]가 true이면 확인 버튼이 error 색상으로 강조됩니다.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String cancelText = '취소',
  String confirmText = '확인',
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => ConfirmDialog(
      title: title,
      content: content,
      cancelText: cancelText,
      confirmText: confirmText,
      destructive: destructive,
    ),
  );
  return confirmed ?? false;
}
