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
    this.todo,
  });

  /// 작업명. 비워 두면 연결한 할 일의 제목, 그것도 없으면 '새 작업'
  final String title;

  /// 연결한 할 일. 연결하지 않으면 null
  final TodoRead? todo;

  /// 집중 시간
  final Duration duration;
}

/// 새 작업 시작 다이얼로그. 분 칸을 [initialDuration]으로 채우고 [initialTodo]를 연결해 연다. 취소하면 null
///
/// 할 일은 [allTodosProvider] 중 [canLinkTimer]인 것을 제목으로 찾아 고른다.
/// 작업명이 비었거나 앞서 고른 할 일의 제목 그대로면 고른 할 일의 제목으로 채운다.
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

  /// 연결할 할 일. 연결하지 않으면 null
  late TodoRead? _todo = widget.initialTodo;

  /// 할 일 제목으로 채운 작업명. 사용자가 고치지 않았으면 다른 할 일을 고를 때 바꾼다
  late String? _filledTitle = widget.initialTodo?.title;

  @override
  void dispose() {
    _title.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _pickTodo(List<TodoRead> todos) async {
    final picked = await showDialog<({TodoRead? todo})>(
      context: context,
      builder: (_) => _TodoPicker(todos: todos, selected: _todo),
    );
    if (picked == null || !mounted) return;
    final todo = picked.todo;
    setState(() {
      _todo = todo;
      if (todo != null &&
          (_title.text.trim().isEmpty || _title.text == _filledTitle)) {
        _title.text = todo.title;
        _filledTitle = todo.title;
      }
    });
  }

  void _submit(int minutes) {
    final typed = _title.text.trim();
    final title = typed.isNotEmpty ? typed : _todo?.title.trim() ?? '';
    Navigator.of(context).pop(
      StartTimerInput(
        title: title.isEmpty ? '새 작업' : title,
        todo: _todo,
        duration: Duration(minutes: minutes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(allTodosProvider);
    // 읽는 중이거나 읽지 못하면 null
    final linkable = todos.value?.where(canLinkTimer).toList();

    return AlertDialog(
      // 키보드가 올라와 높이가 모자라면 내용을 스크롤한다
      scrollable: true,
      title: const Text('새 작업 시작'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: '작업명',
              hintText: '어떤 작업을 시작할까요?',
              border: OutlineInputBorder(),
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
                _todo?.title ?? '연결 안 함',
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

/// 연결할 할 일을 제목으로 찾아 고르는 다이얼로그. 고르면 그 할 일('연결 안 함'은 null)을 담아 닫고, 그냥 닫으면 null
class _TodoPicker extends StatefulWidget {
  const _TodoPicker({required this.todos, required this.selected});

  final List<TodoRead> todos;
  final TodoRead? selected;

  @override
  State<_TodoPicker> createState() => _TodoPickerState();
}

class _TodoPickerState extends State<_TodoPicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _pick(TodoRead? todo) => Navigator.of(context).pop((todo: todo));

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
                    selected: widget.selected == null,
                    onTap: () => _pick(null),
                  ),
                  for (final todo in widget.todos)
                    if (todo.title.toLowerCase().contains(query))
                      ListTile(
                        title: Text(
                          todo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: todo.id == widget.selected?.id,
                        onTap: () => _pick(todo),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
