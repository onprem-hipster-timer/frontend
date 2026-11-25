import 'package:momeet/shared/api/rest/export.dart';

/// 기본 할 일 그룹. 목록을 받기 전이면 null
TodoGroupRead? defaultTodoGroupOf(List<TodoGroupRead>? groups) =>
    groups?.where((group) => group.isDefault).firstOrNull;
