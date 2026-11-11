import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/pages/todo_picker_page.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 새 작업 시작 시트와 할 일 고르기 화면에서 찾을 것들.
///
/// 화면 구조가 바뀌면 이 파일만 고친다. 테스트 본문은 아래 이름으로 무엇을 하는지만 쓴다.
abstract final class StartSheet {
  /// 시트가 열려 있으면 하나
  static final sheet = find.widgetWithText(AppFormSheet, '새 작업 시작');

  static final titleField = find.widgetWithText(TextField, '작업 제목');
  static final todoField = find.widgetWithText(AppPickerField, '할 일');
  static final minutesField = find.widgetWithText(TextField, '직접 입력');

  /// 초까지 정한 집중 시간 칸
  static final exactField = find.widgetWithText(AppPickerField, '정한 시간');
  static final actions = find.byType(AppFormActionBar);
  static final startButton = find.descendant(
    of: actions,
    matching: find.text('시작'),
  );
  static final cancelButton = find.descendant(
    of: actions,
    matching: find.text('취소'),
  );

  /// 할 일 칸에 [text]가 보이면 하나
  static Finder todoShows(String text) =>
      find.descendant(of: todoField, matching: find.text(text));

  /// 정한 시간 칸에 [text]가 보이면 하나
  static Finder exactShows(String text) =>
      find.descendant(of: exactField, matching: find.text(text));

  static Finder presetChip(int minutes) =>
      find.widgetWithText(ChoiceChip, '$minutes분');

  // ---- 할 일 고르기 화면 ----

  static final picker = find.byType(TodoPickerPage);
  static final searchField = find.descendant(
    of: picker,
    matching: find.byType(TextField),
  );

  /// 고르기 화면의 줄('연결 안 함' 포함). 검색 칸에 쓴 글자는 빼고 찾는다
  static Finder pickerItem(String label) => find.descendant(
    of: picker,
    matching: find.byWidgetPredicate((w) => w is Text && w.data == label),
  );

  static Finder checkbox(String label) => find.byWidgetPredicate(
    (widget) => widget is Checkbox && widget.semanticLabel == '$label 고르기',
  );

  /// 'N개 선택 완료' 버튼
  static final confirmPicks = find.descendant(
    of: picker,
    matching: find.textContaining(RegExp(r'^\d+개 선택 완료$')),
  );
}

/// 새 작업 시작 시트에서 하는 일
extension StartSheetActions on WidgetTester {
  String startSheetTitle() =>
      widget<TextField>(StartSheet.titleField).controller!.text;

  bool startSheetTitleEnabled() =>
      widget<TextField>(StartSheet.titleField).enabled ?? true;

  bool startSheetTodoEnabled() =>
      widget<AppPickerField>(StartSheet.todoField).onTap != null;

  bool canStartFromSheet() =>
      widget<AppFormActionBar>(StartSheet.actions).onSubmit != null;

  Future<void> openTodoPicker() async {
    await tap(StartSheet.todoField);
    await pumpAndSettle();
  }

  /// 열린 고르기 화면에서 목록을 굴려 [label] 줄을 보이게 한다.
  /// 목록은 보이는 줄만 그리므로 나타날 때까지 조금씩 굴린다
  Future<void> scrollToPickerItem(String label) async {
    final item = StartSheet.pickerItem(label);
    final list = find
        .descendant(of: StartSheet.picker, matching: find.byType(Scrollable))
        .last;
    for (var i = 0; i < 50 && item.evaluate().isEmpty; i++) {
      await drag(list, const Offset(0, -40));
      await pump();
    }
    await ensureVisible(item.first);
    await pumpAndSettle();
  }

  /// 열린 고르기 화면에서 [label] 줄을 눌러 그 하나를 고른다. 같은 제목이 여럿이면 [index]째
  Future<void> tapPickerItem(String label, {int index = 0}) async {
    await scrollToPickerItem(label);
    await tap(StartSheet.pickerItem(label).at(index));
    await pumpAndSettle();
  }

  /// 고르기 화면을 열고 [label] 줄을 눌러 그 하나를 고른다
  Future<void> chooseTodo(String label) async {
    await openTodoPicker();
    await tapPickerItem(label);
  }

  /// 고르지 않고 고르기 화면을 닫는다
  Future<void> closeTodoPicker() async {
    await tap(
      find.descendant(
        of: StartSheet.picker,
        matching: find.byType(CloseButton),
      ),
    );
    await pumpAndSettle();
  }

  bool? isTodoChecked(String label) =>
      widget<Checkbox>(StartSheet.checkbox(label)).value;

  Future<void> toggleTodo(String label) async {
    await scrollToPickerItem(label);
    await tap(StartSheet.checkbox(label));
    await pump();
  }

  /// 고르기 화면을 열고 [labels]를 차례대로 체크한 뒤 선택 완료를 누른다
  Future<void> checkTodos(List<String> labels) async {
    await openTodoPicker();
    for (final label in labels) {
      await toggleTodo(label);
    }
    await tap(StartSheet.confirmPicks);
    await pumpAndSettle();
  }

  Future<void> enterFocusMinutes(String text) async {
    await enterText(StartSheet.minutesField, text);
    await pump();
  }

  Future<void> choosePreset(int minutes) async {
    await tap(StartSheet.presetChip(minutes));
    await pump();
  }

  Future<void> startFromSheet() async {
    await ensureVisible(StartSheet.startButton);
    await tap(StartSheet.startButton);
    await pumpAndSettle();
  }

  Future<void> cancelStartSheet() async {
    await ensureVisible(StartSheet.cancelButton);
    await tap(StartSheet.cancelButton);
    await pumpAndSettle();
  }
}
