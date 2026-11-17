import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 다이얼 아래 묶음: 상태 문구, 대기 중이면 작업·휴식 고르기, 조작 버튼
///
/// 집중 보기([focus])의 대기 화면은 고르기와 시작 버튼을 한 줄에 둔다.
class TimerDashboardActions extends StatelessWidget {
  const TimerDashboardActions({
    super.key,
    required this.caption,
    required this.alert,
    required this.gap,
    required this.focus,
    required this.breakSelected,
    required this.onBreakSelected,
    required this.controls,
  });

  final String? caption;

  /// 상태 문구를 오류색으로 쓸지
  final bool alert;
  final Widget gap;
  final bool focus;

  /// 대기 중이면 휴식을 골랐는지, 아니면 null(고르기를 두지 않음)
  final bool? breakSelected;
  final ValueChanged<bool> onBreakSelected;
  final Widget controls;

  @override
  Widget build(BuildContext context) {
    final caption = this.caption;
    final breakSelected = this.breakSelected;
    final toggle = breakSelected == null
        ? null
        : _ModeToggle(breakSelected: breakSelected, onChanged: onBreakSelected);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (caption != null) _Caption(caption, alert: alert),
        gap,
        if (toggle != null && focus)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: toggle),
              const SizedBox(width: 12),
              controls,
            ],
          )
        else ...[
          if (toggle != null) ...[toggle, gap],
          controls,
        ],
      ],
    );
  }
}

/// 다이얼 아래 상태 문구. [alert]면 오류색
class _Caption extends StatelessWidget {
  const _Caption(this.text, {required this.alert});

  final String text;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: alert
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// 대기 중 작업·휴식 고르기
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.breakSelected, required this.onChanged});

  final bool breakSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: false,
          label: Text(Terms.focus),
          icon: Icon(Icons.timer_outlined),
        ),
        ButtonSegment(
          value: true,
          label: Text(Terms.rest),
          icon: Icon(Icons.coffee_outlined),
        ),
      ],
      selected: {breakSelected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}
