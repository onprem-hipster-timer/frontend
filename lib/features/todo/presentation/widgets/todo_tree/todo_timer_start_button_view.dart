import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 할 일 줄의 타이머 시작 버튼. 새 타이머를 시작하는 중([starting])에는 누를 수 없다
class TodoTimerStartButtonView extends StatelessWidget {
  const TodoTimerStartButtonView({
    super.key,
    required this.starting,
    required this.onPressed,
  });

  final bool starting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.play_circle_outline),
      tooltip: '${Terms.timer} 시작',
      visualDensity: VisualDensity.compact,
      onPressed: starting ? null : onPressed,
    );
  }
}
