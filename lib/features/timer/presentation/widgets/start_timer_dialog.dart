import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// 새 작업 시작 다이얼로그에서 고른 값
class StartTimerInput {
  const StartTimerInput({required this.title, required this.duration});

  /// 작업명. 비워 두면 '새 작업'
  final String title;

  /// 집중 시간
  final Duration duration;
}

/// 새 작업 시작 다이얼로그. 분 칸을 [initialDuration]으로 채워 연다. 취소하면 null
///
/// 테스트: test/features/timer/presentation/pages/timer_page_test.dart
Future<StartTimerInput?> showStartTimerDialog(
  BuildContext context, {
  required Duration initialDuration,
}) {
  return showDialog<StartTimerInput>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _StartTimerDialog(initialDuration: initialDuration),
  );
}

class _StartTimerDialog extends StatefulWidget {
  const _StartTimerDialog({required this.initialDuration});

  final Duration initialDuration;

  @override
  State<_StartTimerDialog> createState() => _StartTimerDialogState();
}

class _StartTimerDialogState extends State<_StartTimerDialog> {
  final _title = TextEditingController();
  late final _minutes = TextEditingController(
    text: '${widget.initialDuration.inMinutes}',
  );

  @override
  void dispose() {
    _title.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _submit(int minutes) {
    final title = _title.text.trim();
    Navigator.of(context).pop(
      StartTimerInput(
        title: title.isEmpty ? '새 작업' : title,
        duration: Duration(minutes: minutes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
