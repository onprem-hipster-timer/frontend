import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_shading.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_autosave.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_answer_reset.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_brush_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_grid.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_brush_zone.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_help_icon.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_layout.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_reset_confirm.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_save_indicator.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_timezone_label.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// '내 시간 선택하기'를 영역으로 나눠 쌓는다: 제목 줄(시간별이면 하루 범위, 도움말, 저장 상태)과 시간 기준
/// 한 줄 → 칠하기 조작(붓 고르기) → 격자와 그 아래 옅은 색 설명. 영역 사이는 영역 안보다 넓게 띄운다.
///
/// 붓은 '가능'으로 시작한다([MeetingBrushZone]). 끌기와 붓 쓰는 법은 도움말에 둔다. [onPaint]가 없으면(로그인 전) 도움말·저장
/// 상태·붓 대신 조작 자리에 로그인하면 칠할 수 있다고 적고, 칸을 누르면 [onLocked]를 부른다.
class MeetingAvailabilitySection extends StatefulWidget {
  const MeetingAvailabilitySection({
    super.key,
    required this.meeting,
    required this.shading,
    this.status = MeetingSaveStatus.idle,
    this.onPaint,
    this.onRetry,
    this.onLocked,
  });

  final MeetingRead meeting;
  final MeetingShading shading;
  final MeetingSaveStatus status;
  final MeetingPaint? onPaint;
  final VoidCallback? onRetry;
  final VoidCallback? onLocked;

  @override
  State<MeetingAvailabilitySection> createState() =>
      _MeetingAvailabilitySectionState();
}

class _MeetingAvailabilitySectionState
    extends State<MeetingAvailabilitySection> {
  /// 영역 사이 간격
  static const _zoneGap = 20.0;

  var _brush = MeetingAnswer.available;

  /// 시간별 날짜 열마다 떤 횟수, 붓 줄을 떤 횟수
  final _dayShakes = <int, int>{};
  var _brushShakes = 0;

  /// 막힌 붓질 알림이 떠 있는지. 떠 있는 동안 또 막히면 떨기만 한다
  var _blockedOpen = false;

  /// [question]으로 한 번 묻고, 초기화하면 [cells]의 내 답을 지운다(되돌리기 알림 없이. 묻는 것이 그 안전판이다)
  Future<void> _confirmReset(
    Iterable<MeetingCell> cells,
    String question,
  ) async {
    final wide = !MeetingLayout.narrow(MediaQuery.sizeOf(context).width);
    if (!await askResetMeetingAnswers(
          context,
          question: keepWords(question),
          wide: wide,
        ) ||
        !mounted) {
      return;
    }
    final MeetingAvailabilitySection(:shading, :onPaint) = widget;
    onPaint?.call({
      for (final cell in cells)
        if (shading.answerAt(cell) != MeetingAnswer.unanswered)
          cell: MeetingAnswer.unanswered,
    });
  }

  /// 시간별 날짜 머리로 답한 날([day])을 지운다. 되돌리기 알림을 띄운다
  void _resetDay(List<MeetingCell> day) {
    final onPaint = widget.onPaint;
    if (onPaint == null) return;
    resetMeetingAnswers(
      ScaffoldMessenger.of(context),
      shading: widget.shading,
      cells: day,
      onPaint: onPaint,
      done: meetingDayResetDone(day.first.day),
    );
  }

  /// 다른 방식으로 표시한 묶음에 칠하려 했다: 그 자리를 떨고, 까닭과 초기화 단추를 알린다
  void _blocked(List<List<MeetingCell>> groups) {
    final mode = widget.shading.grid.mode;
    setState(() {
      if (mode == MeetingMode.hourly) {
        _dayShakes.update(
          groups.first.first.column,
          (n) => n + 1,
          ifAbsent: () => 1,
        );
      } else {
        _brushShakes++;
      }
    });
    if (_blockedOpen) return;
    final text = meetingBlockedText(_brush, mode, [
      for (final group in groups) group.first.day,
    ]);
    _blockedOpen = true;
    ScaffoldMessenger.of(context)
        .showAppSnackBar(
          keepWords(text.message),
          actionLabel: text.action,
          onAction: () => _confirmReset([
            for (final group in groups) ...group,
          ], text.question),
        )
        .closed
        .whenComplete(() => _blockedOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final MeetingAvailabilitySection(:shading, :onPaint, :onLocked) = widget;
    final touch = switch (Theme.of(context).platform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => true,
      _ => false,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(
          meeting: widget.meeting,
          hourly: shading.grid.mode == MeetingMode.hourly,
          status: widget.status,
          help: onPaint == null
              ? null
              : meetingBrushHelp(shading.grid.mode, touch: touch),
          onRetry: widget.onRetry,
        ),
        const SizedBox(height: _zoneGap),
        if (onPaint == null)
          const _Hint(icon: Icons.lock_outline, text: '로그인하면 내 시간을 칠할 수 있어요')
        else
          MeetingBrushZone(
            brush: _brush,
            mode: shading.grid.mode,
            shakes: _brushShakes,
            onBrushChanged: (brush) => setState(() => _brush = brush),
            onClearAll:
                shading.grid.cells.any(
                  (cell) => shading.answerAt(cell) != MeetingAnswer.unanswered,
                )
                ? () => _confirmReset(
                    shading.grid.cells,
                    meetingResetQuestion(shading.grid.mode, const []),
                  )
                : null,
          ),
        const SizedBox(height: _zoneGap + 4),
        MeetingAvailabilityGrid(
          shading: shading,
          brush: _brush,
          onPaint: onPaint,
          onBlocked: _blocked,
          onResetDay: _resetDay,
          dayShakes: _dayShakes,
          onLocked: onLocked,
        ),
      ],
    );
  }
}

/// 제목 영역: '내 시간 선택하기'와 하루 범위·도움말([help]가 있을 때)·저장 상태, 그 아래 시간 기준 한 줄
class _Heading extends StatelessWidget {
  const _Heading({
    required this.meeting,
    required this.hourly,
    required this.status,
    required this.help,
    required this.onRetry,
  });

  final MeetingRead meeting;
  final bool hourly;
  final MeetingSaveStatus status;
  final String? help;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final help = this.help;
    final onRetry = this.onRetry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Semantics(
              header: true,
              child: Text(
                '내 시간 선택하기',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (hourly) _RangeChip(meetingHoursText(meeting)),
            if (help != null) MeetingHelpIcon(help),
            if (help != null && onRetry != null)
              MeetingSaveIndicator(status: status, onRetry: onRetry),
          ],
        ),
        const SizedBox(height: 4),
        MeetingTimezoneLabel(meeting.timezone),
      ],
    );
  }
}

/// 조작 자리의 짧은 안내 한 줄
class _Hint extends StatelessWidget {
  const _Hint({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Row(
      children: [
        Icon(icon, size: 16, color: caption?.color),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: caption)),
      ],
    );
  }
}

/// 시간별 하루 범위 알약
class _RangeChip extends StatelessWidget {
  const _RangeChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.pillAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Text(text, style: theme.textTheme.labelMedium),
      ),
    );
  }
}
