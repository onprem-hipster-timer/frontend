import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dial.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_gallery.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_timer.dart';

@widgetbook.UseCase(name: '활성 타이머 넘겨 보기', type: TimerGallery, path: '[타이머]')
Widget timerGallery(BuildContext context) {
  final knobs = context.knobs;
  final count = knobs.int.slider(
    label: '타이머 수',
    initialValue: 3,
    min: 2,
    max: 6,
    description: '내 활성 타이머가 둘 이상이면 대시보드 다이얼 자리가 이 갤러리가 된다',
  );
  final arrows = knobs.boolean(
    label: '이전·다음 버튼',
    description: '넓은 화면이나 웹·데스크톱에서 쪽 표시 양옆에 둔다',
  );
  // 앱에서는 대시보드 양옆 24 여백 안의 다이얼 자리를 채운다
  return Padding(
    padding: const EdgeInsets.all(24),
    child: _Gallery(count: count, arrows: arrows),
  );
}

/// 넘긴 쪽을 고른 타이머로 들고 있어 쪽 표시가 따라 바뀐다
class _Gallery extends StatefulWidget {
  const _Gallery({required this.count, required this.arrows});

  final int count;
  final bool arrows;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  String _focusedId = 'timer-0';

  /// 쪽마다 다른 남은 시간·상태
  static const _remaining = [
    Duration(minutes: 12, seconds: 34),
    Duration(minutes: 40),
    Duration.zero,
    Duration(minutes: 5, seconds: 10),
    Duration(minutes: 50),
    Duration(minutes: 1, seconds: 30),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timers = [
      for (var i = 0; i < widget.count; i++)
        sampleTimer(
          index: i,
          allocated: const Duration(minutes: 50),
          remaining: _remaining[i],
          status: i == 1 ? TimerStatus.paused : TimerStatus.running,
        ),
    ];
    final focusedId = timers.any((timer) => timer.id == _focusedId)
        ? _focusedId
        : timers.first.id;
    return TimerGallery(
      timers: timers,
      focusedId: focusedId,
      arrows: widget.arrows,
      onFocus: (id) => setState(() => _focusedId = id),
      pageBuilder: (timer) {
        final remaining = Duration(
          seconds: timer.allocatedDuration - timer.elapsedTime,
        );
        final state = remaining == Duration.zero
            ? SampleTimerState.timeUp
            : timer.status == TimerStatus.paused
            ? SampleTimerState.paused
            : SampleTimerState.running;
        return TimerDial(
          remaining: remaining,
          face: dialFaceFor(Duration(seconds: timer.allocatedDuration)),
          color: sampleDialColor(colorScheme, state),
        );
      },
    );
  }
}
