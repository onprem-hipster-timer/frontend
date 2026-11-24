import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/core/turnstile/turnstile_field.dart';
import 'package:widgetbook/widgetbook.dart';

/// 사람 확인 상자의 상태와 그 화면 이름
const _turnstileStates = {
  '확인됨': TurnstileStatus.ready,
  '확인하는 중': TurnstileStatus.verifying,
  '눌러야 함': TurnstileStatus.interactive,
  '확인 실패': TurnstileStatus.failed,
  '불러오지 못함': TurnstileStatus.unavailable,
};

/// '확인 상자' 노브
TurnstileStatus turnstileKnob(
  BuildContext context, {
  required String description,
}) {
  final state = context.knobs.object.dropdown(
    label: '확인 상자',
    description: description,
    options: _turnstileStates.keys.toList(),
  );
  return _turnstileStates[state]!;
}

/// [status]에 머무는 사람 확인 상자와 그 아래 안내([TurnstileField])
class SampleTurnstileField extends StatefulWidget {
  const SampleTurnstileField({super.key, required this.status});

  final TurnstileStatus status;

  @override
  State<SampleTurnstileField> createState() => _SampleTurnstileFieldState();
}

class _SampleTurnstileFieldState extends State<SampleTurnstileField> {
  late final _controller = SampleTurnstile(widget.status);

  @override
  void didUpdateWidget(SampleTurnstileField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller._status.value = widget.status;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TurnstileField(controller: _controller);
}

/// 사람 확인 상자 자리. 고른 상태로 머물고, 확인됐으면 토큰을 바로 준다
class SampleTurnstile implements TurnstileController {
  SampleTurnstile(TurnstileStatus status) : _status = ValueNotifier(status);

  final ValueNotifier<TurnstileStatus> _status;

  @override
  ValueListenable<TurnstileStatus> get status => _status;

  @override
  Widget buildBox(BuildContext context) => const _TurnstileBox();

  @override
  Future<String> nextToken() => _status.value == TurnstileStatus.ready
      ? Future.value('sample-token')
      : Future.error(TurnstileException(_status.value));

  @override
  void reset() {}

  @override
  void dispose() => _status.dispose();
}

/// 웹에서 Cloudflare가 그리는 확인 상자와 같은 크기의 빈 자리
class _TurnstileBox extends StatelessWidget {
  const _TurnstileBox();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 300,
        height: 65,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '사람 확인 상자',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
