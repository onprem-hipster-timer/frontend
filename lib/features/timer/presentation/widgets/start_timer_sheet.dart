import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/features/timer/presentation/widgets/duration_picker_sheet.dart';
import 'package:momeet/features/todo/presentation/pages/todo_picker_page.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 새 작업 시작에서 고를 수 있는 집중 시간
const _focusDurationPresets = [
  Duration(minutes: 15),
  Duration(minutes: 25),
  Duration(minutes: 45),
  Duration(minutes: 60),
];

/// 새 작업 시작에 입력할 수 있는 가장 긴 집중 시간 (분)
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

/// 새 작업 시작에서 고른 값
class StartTimerInput {
  const StartTimerInput({
    required this.title,
    required this.duration,
    this.todos = const [],
  });

  /// 작업 제목. 비워 두면 연결한 할 일의 제목, 그것도 없으면 '새 작업'. 할 일이 둘 이상이면 쓰지 않는다
  final String title;

  /// 연결한 할 일. 연결하지 않으면 비어 있다. 둘 이상이면 할 일마다 그 제목으로 타이머를 하나씩 시작한다
  final List<TodoRead> todos;

  /// 집중 시간
  final Duration duration;
}

/// 타이머를 시작하지 못한 [failed] 할 일을 알리는 문구
String startFailureMessage(List<TodoRead> failed) =>
    '타이머 시작 실패: ${failed.map((todo) => todo.title).join(', ')}';

/// 새 작업 시작 시트. 집중 시간을 [initialDuration]으로, 할 일을 [initialTodo]로 채워 연다. 닫으면 null
///
/// [initialDuration]에 초가 있으면 직접 입력 칸 대신 그 시간을 그대로 보이고 '변경'으로 '시간 정하기'를 다시 연다.
/// 집중 시간 칩을 누르면 직접 입력으로 돌아간다.
/// 할 일은 [showTodoPicker]로 [canLinkTimer]인 것 중에서 고른다.
/// 할 일을 하나 고르면 작업 제목이 비었거나 앞서 고른 할 일의 제목 그대로일 때 그 제목으로 채운다.
/// 둘 이상 고르면 작업 제목 칸을 막고, 할 일마다 그 제목으로 타이머를 하나씩 시작한다.
///
/// 테스트: test/features/timer/presentation/widgets/start_timer_sheet_test.dart
Future<StartTimerInput?> showStartTimerSheet(
  BuildContext context, {
  required Duration initialDuration,
  TodoRead? initialTodo,
}) => showAppSheet<StartTimerInput>(
  context,
  builder: (_) => _StartTimerSheet(
    initialDuration: initialDuration,
    initialTodo: initialTodo,
  ),
);

class _StartTimerSheet extends ConsumerStatefulWidget {
  const _StartTimerSheet({required this.initialDuration, this.initialTodo});

  final Duration initialDuration;
  final TodoRead? initialTodo;

  @override
  ConsumerState<_StartTimerSheet> createState() => _StartTimerSheetState();
}

class _StartTimerSheetState extends ConsumerState<_StartTimerSheet> {
  late final _title = TextEditingController(text: widget.initialTodo?.title);
  late final _minutes = TextEditingController(
    text: '${widget.initialDuration.inMinutes}',
  );

  /// 초까지 고른 집중 시간. 직접 입력으로 고르면 null
  late Duration? _exact = widget.initialDuration.inSeconds % 60 == 0
      ? null
      : widget.initialDuration;

  /// 연결할 할 일. 연결하지 않으면 비어 있다
  late List<TodoRead> _todos = [?widget.initialTodo];

  /// 할 일 제목으로 채운 작업 제목. 사용자가 고치지 않았으면 다른 할 일을 고를 때 바꾼다
  late String? _filledTitle = widget.initialTodo?.title;

  @override
  void dispose() {
    _title.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _pickTodos() async {
    final picked = await showTodoPicker(
      context,
      selectable: canLinkTimer,
      selected: _todos,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _todos = picked;
      final todo = picked.length == 1 ? picked.single : null;
      if (todo != null &&
          (_title.text.trim().isEmpty || _title.text == _filledTitle)) {
        _title.text = todo.title;
        _filledTitle = todo.title;
      }
    });
  }

  Future<void> _changeExact(Duration current) async {
    final picked = await showDurationPickerSheet(context, initial: current);
    if (picked == null || !mounted) return;
    setState(() {
      if (picked.inSeconds % 60 == 0) {
        _exact = null;
        _minutes.text = '${picked.inMinutes}';
      } else {
        _exact = picked;
      }
    });
  }

  void _choosePreset(Duration preset) {
    setState(() => _exact = null);
    _minutes.text = '${preset.inMinutes}';
  }

  void _submit(Duration duration) {
    final typed = _title.text.trim();
    final title = typed.isNotEmpty
        ? typed
        : _todos.firstOrNull?.title.trim() ?? '';
    Navigator.of(context).pop(
      StartTimerInput(
        title: title.isEmpty ? '새 작업' : title,
        todos: _todos,
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(allTodosProvider);
    final several = _todos.length >= 2;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _minutes,
      builder: (context, minutesText, _) {
        final minutes = _focusMinutes(minutesText.text);
        final exact = _exact;
        final duration =
            exact ?? (minutes == null ? null : Duration(minutes: minutes));
        return AppFormSheet(
          title: '새 작업 시작',
          actions: AppFormActionBar(
            submitLabel: '시작',
            onSubmit: duration == null ? null : () => _submit(duration),
          ),
          children: [
            TextField(
              controller: _title,
              enabled: !several,
              decoration: InputDecoration(
                labelText: '작업 제목',
                hintText: '어떤 작업을 시작할까요?',
                helperText: several ? '할 일마다 그 제목으로 타이머를 하나씩 시작합니다' : null,
                helperMaxLines: 2,
              ),
            ),
            AppPickerField(
              label: '할 일',
              icon: Icons.task_alt,
              value: switch (_todos) {
                [] => null,
                [final todo] => todo.title,
                [final first, ...final rest] =>
                  '${first.title} 외 ${rest.length}개',
              },
              placeholder: '연결 안 함',
              errorText: todos.hasError ? '할 일을 불러오지 못했습니다' : null,
              onTap: todos.hasValue ? _pickTodos : null,
              onClear: () => setState(() => _todos = []),
            ),
            _FocusDurationField(
              minutes: _minutes,
              current: minutes,
              exact: exact,
              onPreset: _choosePreset,
              onChangeExact: _changeExact,
            ),
          ],
        );
      },
    );
  }
}

/// 집중 시간: 자주 쓰는 시간 칩과 분 직접 입력. 초까지 고른 시간이면 입력 대신 그 시간과 '변경'
class _FocusDurationField extends StatelessWidget {
  const _FocusDurationField({
    required this.minutes,
    required this.current,
    required this.exact,
    required this.onPreset,
    required this.onChangeExact,
  });

  final TextEditingController minutes;

  /// 직접 입력한 분이 맞으면 그 값, 아니면 null
  final int? current;
  final Duration? exact;
  final void Function(Duration preset) onPreset;
  final void Function(Duration current) onChangeExact;

  @override
  Widget build(BuildContext context) {
    final exact = this.exact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader('집중 시간'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _focusDurationPresets)
              ChoiceChip(
                label: Text('${preset.inMinutes}분'),
                selected: exact == null && preset.inMinutes == current,
                onSelected: (_) => onPreset(preset),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (exact != null)
          AppPickerField(
            label: '정한 시간',
            icon: Icons.timer_outlined,
            value: formatDuration(exact),
            onTap: () => onChangeExact(exact),
          )
        else
          TextField(
            controller: minutes,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: '직접 입력',
              suffixText: '분',
              errorText: current == null ? '1~$_maxFocusMinutes분' : null,
            ),
          ),
      ],
    );
  }
}
