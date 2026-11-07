import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/widgets/choice_dialog.dart';

/// 할 일·일정을 삭제할 때 연결된 타이머를 어떻게 할지 묻는다. 닫으면 null.
Future<LinkedTimerPolicy?> showLinkedTimerPolicyDialog(
  BuildContext context, {
  required String itemTitle,
}) {
  return showChoiceDialog<LinkedTimerPolicy>(
    context,
    title: '연결된 타이머 처리',
    content: '"$itemTitle"에 연결된 타이머가 있습니다.\n그 타이머를 어떻게 할까요?',
    choices: const [
      DialogChoice(
        value: LinkedTimerPolicy.unlink,
        label: '연결만 해제',
        description: '타이머 기록은 남기고, 실행 중이면 계속 실행합니다',
      ),
      DialogChoice(
        value: LinkedTimerPolicy.delete,
        label: '타이머 삭제',
        description: '타이머 기록도 함께 지웁니다',
      ),
    ],
  );
}

/// [delete]를 연결 타이머 정책 없이 보내고, 서버가 정책을 요구하면(422) 물어서 다시 보낸다.
///
/// 연결 타이머가 있는지는 서버만 알아서 먼저 묻지 않는다. 다이얼로그를 닫으면 다시 보내지 않고 false.
///
/// 테스트: test/features/todo/presentation/utils/todo_actions_test.dart
Future<bool> deleteAskingLinkedTimerPolicy(
  BuildContext context, {
  required String itemTitle,
  required Future<void> Function(LinkedTimerPolicy? policy) delete,
}) async {
  try {
    await delete(null);
    return true;
  } on DioException catch (error) {
    final requiresPolicy = switch (error.response?.data) {
      {'error_type': 'LinkedTimerPolicyRequiredError'} => true,
      _ => false,
    };
    if (!requiresPolicy) rethrow;
  }
  if (!context.mounted) return false;
  final policy = await showLinkedTimerPolicyDialog(
    context,
    itemTitle: itemTitle,
  );
  if (policy == null) return false;
  await delete(policy);
  return true;
}
