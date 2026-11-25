import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 마감일 고르기. 고르지 않고 닫으면 null
Future<DateTime?> pickTodoDeadline(BuildContext context, DateTime? current) {
  return showAppDatePicker(context, initial: current ?? DateTime.now());
}

/// 할 일 폼에서 고른 값. [description]이 비었으면 설명이 없고, [todoGroupId]가 null이면 기본 그룹이다
typedef TodoFormValues = ({
  String title,
  String description,
  TodoStatus status,
  List<String> tagIds,
  DateTime? deadline,
  String? todoGroupId,
});
