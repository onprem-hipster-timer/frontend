import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// '시간 정하기'에서 고를 수 있는 가장 긴 시간
const maxPickedDuration = Duration(minutes: 600);

/// 시·분·초 바퀴로 시간을 고르는 '시간 정하기' 바텀 시트를 [initial]로 연다.
///
/// 확인하면 고른 값을 [maxPickedDuration]보다 길지 않게 잘라 돌려주고, 취소하거나 닫으면 null.
/// 0초면 확인을 막는다.
///
/// 테스트: test/features/timer/presentation/pages/timer_page_test.dart ('시간 정하기')
Future<Duration?> showDurationPickerSheet(
  BuildContext context, {
  required Duration initial,
}) => showAppSheet<Duration>(
  context,
  builder: (_) => _DurationPickerSheet(initial: initial),
);

class _DurationPickerSheet extends StatefulWidget {
  const _DurationPickerSheet({required this.initial});

  final Duration initial;

  @override
  State<_DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<_DurationPickerSheet> {
  late Duration _picked = widget.initial > maxPickedDuration
      ? maxPickedDuration
      : widget.initial;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('시간 정하기', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(
              height: 216,
              // 웹·데스크톱에서도 마우스로 휠을 끌어 돌린다 (기본 스크롤 동작은 마우스 끌기를 받지 않는다)
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(dragDevices: {...PointerDeviceKind.values}),
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hms,
                  initialTimerDuration: _picked,
                  onTimerDurationChanged: (duration) =>
                      setState(() => _picked = duration),
                ),
              ),
            ),
            AppFormActionBar(
              submitLabel: '확인',
              onSubmit: _picked == Duration.zero
                  ? null
                  : () => Navigator.of(context).pop(
                      _picked > maxPickedDuration ? maxPickedDuration : _picked,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
