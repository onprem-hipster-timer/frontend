import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_paint_keys_view.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '칠한 것 되돌리기 키',
  type: MeetingPaintKeysView,
  path: '[모임]/내 시간 선택하기',
)
Widget meetingPaintKeysView(BuildContext context) {
  // 앱에서는 내 시간을 칠하는 모임 화면 본문 전체를 감싸고, 되돌리면 칠한 것과 같이 저장한다
  return const _PaintKeysPreview();
}

/// 키를 받은 본문과 마지막으로 받은 키
class _PaintKeysPreview extends StatefulWidget {
  const _PaintKeysPreview();

  @override
  State<_PaintKeysPreview> createState() => _PaintKeysPreviewState();
}

class _PaintKeysPreviewState extends State<_PaintKeysPreview> {
  var _last = '아직 받은 키가 없어요';
  var _count = 0;

  void _receive(String label) => setState(() {
    _count++;
    _last = '$label ($_count)';
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MeetingPaintKeysView(
      onUndo: () => _receive('되돌리기'),
      onRedo: () => _receive('다시 칠하기'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ctrl+Z(macOS는 Cmd+Z)로 되돌리고, Ctrl+Y·Ctrl+Shift+Z(macOS는 Cmd+Shift+Z)로 다시 칠해요. '
              '본문을 누르고 있는 동안은 받지 않아요',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(_last, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
