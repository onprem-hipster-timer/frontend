import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 새 작업 시작 다이얼로그에서 고를 수 있는 집중 시간
const _focusDurationPresets = [
  Duration(minutes: 15),
  Duration(minutes: 25),
  Duration(minutes: 45),
  Duration(minutes: 60),
];

/// 새 작업 시작 다이얼로그에 입력할 수 있는 가장 긴 집중 시간 (분)
const _maxFocusMinutes = 600;

/// [text]가 1~[_maxFocusMinutes] 사이의 분이면 그 값, 아니면 null
int? _focusMinutes(String text) {
  final minutes = int.tryParse(text);
  if (minutes == null || minutes < 1 || minutes > _maxFocusMinutes) {
    return null;
  }
  return minutes;
}

/// 새 타이머에 연결할 수 있는 할 일인지. 서버는 내 할 일만 연결하고, 완료·취소한 할 일은 고르지 않는다
bool canLinkTimer(TodoRead todo) =>
    !todo.isShared &&
    todo.status != TodoStatus.done &&
    todo.status != TodoStatus.cancelled;

/// 새 작업 시작 다이얼로그에서 고른 값
class StartTimerInput {
  const StartTimerInput({
    required this.title,
    required this.duration,
    this.todos = const [],
  });

  /// 작업명. 비워 두면 연결한 할 일의 제목, 그것도 없으면 '새 작업'. 할 일이 둘 이상이면 쓰지 않는다
  final String title;

  /// 연결한 할 일. 연결하지 않으면 비어 있다. 둘 이상이면 할 일마다 그 제목으로 타이머를 하나씩 시작한다
  final List<TodoRead> todos;

  /// 집중 시간
  final Duration duration;
}

/// 타이머를 시작하지 못한 [failed] 할 일을 알리는 문구
String startFailureMessage(List<TodoRead> failed) =>
    '타이머 시작 실패: ${failed.map((todo) => todo.title).join(', ')}';

/// 새 작업 시작 다이얼로그. 분 칸을 [initialDuration]으로 채우고 [initialTodo]를 연결해 연다. 취소하면 null
///
/// 할 일은 [allTodosProvider] 중 [canLinkTimer]인 것을 제목으로 찾아 고르고, 체크해 여럿을 고를 수 있다.
/// 할 일을 하나 고르면 작업명이 비었거나 앞서 고른 할 일의 제목 그대로일 때 그 할 일의 제목으로 채운다.
/// 둘 이상 고르면 작업명 칸을 막는다. 할 일마다 그 제목으로 타이머를 하나씩 시작한다.
///
/// 테스트: test/features/timer/presentation/widgets/start_timer_dialog_test.dart
Future<StartTimerInput?> showStartTimerDialog(
  BuildContext context, {
  required Duration initialDuration,
  TodoRead? initialTodo,
}) {
  return showDialog<StartTimerInput>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _StartTimerDialog(
      initialDuration: initialDuration,
      initialTodo: initialTodo,
    ),
  );
}

class _StartTimerDialog extends ConsumerStatefulWidget {
  const _StartTimerDialog({required this.initialDuration, this.initialTodo});

  final Duration initialDuration;
  final TodoRead? initialTodo;

  @override
  ConsumerState<_StartTimerDialog> createState() => _StartTimerDialogState();
}

class _StartTimerDialogState extends ConsumerState<_StartTimerDialog> {
  late final _title = TextEditingController(text: widget.initialTodo?.title);
  late final _minutes = TextEditingController(
    text: '${widget.initialDuration.inMinutes}',
  );

  /// 연결할 할 일. 연결하지 않으면 비어 있다
  late List<TodoRead> _todos = [?widget.initialTodo];

  /// 할 일 제목으로 채운 작업명. 사용자가 고치지 않았으면 다른 할 일을 고를 때 바꾼다
  late String? _filledTitle = widget.initialTodo?.title;

  @override
  void dispose() {
    _title.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _pickTodo(List<TodoRead> todos) async {
    final picked = await showDialog<({List<TodoRead> todos})>(
      context: context,
      builder: (_) => _TodoPicker(todos: todos, selected: _todos),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _todos = picked.todos;
      final todo = _todos.length == 1 ? _todos.single : null;
      if (todo != null &&
          (_title.text.trim().isEmpty || _title.text == _filledTitle)) {
        _title.text = todo.title;
        _filledTitle = todo.title;
      }
    });
  }

  void _submit(int minutes) {
    final typed = _title.text.trim();
    final title = typed.isNotEmpty
        ? typed
        : _todos.firstOrNull?.title.trim() ?? '';
    Navigator.of(context).pop(
      StartTimerInput(
        title: title.isEmpty ? '새 작업' : title,
        todos: _todos,
        duration: Duration(minutes: minutes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(allTodosProvider);
    // 읽는 중이거나 읽지 못하면 null
    final linkable = todos.value?.where(canLinkTimer).toList();
    final several = _todos.length >= 2;

    return AlertDialog(
      // 키보드가 올라와 높이가 모자라면 내용을 스크롤한다
      scrollable: true,
      title: const Text('새 작업 시작'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            enabled: !several,
            decoration: InputDecoration(
              labelText: '작업명',
              hintText: '어떤 작업을 시작할까요?',
              helperText: several ? '할 일마다 그 제목으로 타이머를 하나씩 시작합니다' : null,
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: linkable == null ? null : () => _pickTodo(linkable),
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '할 일 연결 (선택)',
                helperText: linkable == null && todos.hasError
                    ? '할 일을 불러오지 못했습니다'
                    : null,
                enabled: linkable != null,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                switch (_todos) {
                  [] => '연결 안 함',
                  [final todo] => todo.title,
                  [final first, ...final rest] =>
                    '${first.title} 외 ${rest.length}개',
                },
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _minutes,
            builder: (_, value, _) {
              final minutes = _focusMinutes(value.text);
              return Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final preset in _focusDurationPresets)
                    ChoiceChip(
                      label: Text('${preset.inMinutes}분'),
                      selected: preset.inMinutes == minutes,
                      onSelected: (_) => _minutes.text = '${preset.inMinutes}',
                    ),
                  SizedBox(
                    width: 96,
                    child: TextFormField(
                      controller: _minutes,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        suffixText: '분',
                        border: const OutlineInputBorder(),
                        errorText: minutes == null
                            ? '1~$_maxFocusMinutes분'
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _minutes,
          builder: (_, value, _) {
            final minutes = _focusMinutes(value.text);
            return FilledButton(
              onPressed: minutes == null ? null : () => _submit(minutes),
              child: const Text('시작'),
            );
          },
        ),
      ],
    );
  }
}

/// 연결할 할 일을 제목으로 찾아 고르는 다이얼로그. 그냥 닫으면 null
///
/// 할 일을 누르면 그 할 일 하나만, '연결 안 함'을 누르면 빈 목록을 담아 바로 닫는다.
/// 체크 상자로 둘 이상 고르면 나오는 'N개 선택 완료'를 누르면 체크한 차례대로 담아 닫는다. [selected]를 체크한 채 연다.
class _TodoPicker extends StatefulWidget {
  const _TodoPicker({required this.todos, required this.selected});

  final List<TodoRead> todos;
  final List<TodoRead> selected;

  @override
  State<_TodoPicker> createState() => _TodoPickerState();
}

class _TodoPickerState extends State<_TodoPicker> {
  final _query = TextEditingController();

  /// 체크한 할 일. 체크한 차례대로
  late final _checked = [...widget.selected];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _isChecked(TodoRead todo) => _checked.any((it) => it.id == todo.id);

  void _toggle(TodoRead todo) => setState(() {
    if (_isChecked(todo)) {
      _checked.removeWhere((it) => it.id == todo.id);
    } else {
      _checked.add(todo);
    }
  });

  void _pick(List<TodoRead> todos) => Navigator.of(context).pop((todos: todos));

  @override
  Widget build(BuildContext context) {
    final query = _query.text.trim().toLowerCase();

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _query,
                decoration: const InputDecoration(
                  hintText: '제목으로 찾기',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  ListTile(
                    title: const Text('연결 안 함'),
                    selected: _checked.isEmpty,
                    onTap: () => _pick(const []),
                  ),
                  for (final todo in widget.todos)
                    if (todo.title.toLowerCase().contains(query))
                      ListTile(
                        leading: Checkbox(
                          value: _isChecked(todo),
                          onChanged: (_) => _toggle(todo),
                        ),
                        title: Text(
                          todo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: _isChecked(todo),
                        onTap: () => _pick([todo]),
                      ),
                ],
              ),
            ),
            // 하나는 그 할 일을 눌러 고르므로 둘 이상 체크했을 때만 둔다
            if (_checked.length >= 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => _pick([..._checked]),
                    child: Text('${_checked.length}개 선택 완료'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
