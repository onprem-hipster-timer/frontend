import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';

void main() {
  group('todoStatusForRequest', () {
    test('미예정·예정됨은 보내지 않는다 (서버가 마감일로 정함)', () {
      expect(todoStatusForRequest(TodoStatus.unscheduled), isNull);
      expect(todoStatusForRequest(TodoStatus.scheduled), isNull);
    });

    test('완료·취소는 그대로 보낸다', () {
      expect(todoStatusForRequest(TodoStatus.done), TodoStatus.done);
      expect(todoStatusForRequest(TodoStatus.cancelled), TodoStatus.cancelled);
    });
  });
}
