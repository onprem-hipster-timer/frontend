import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 화면을 덮는 어두운 바탕 위, 아래에 붙은 하단 시트 모양([showAppSheet]의 손잡이·모서리·배경).
class SheetPreview extends StatelessWidget {
  const SheetPreview({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: Colors.black54,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: theme.colorScheme.surface,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 48,
                child: Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: AppRadius.pillAll,
                    ),
                  ),
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// 화면을 덮는 어두운 바탕 위의 다이얼로그. 단추가 창을 닫아도 다시 띄워 미리보기가 비지 않게 한다.
class DialogPreview extends StatefulWidget {
  const DialogPreview({super.key, required this.child});

  final Widget child;

  @override
  State<DialogPreview> createState() => _DialogPreviewState();
}

class _DialogPreviewState extends State<DialogPreview> {
  var _shown = 0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Navigator(
        key: ValueKey(_shown),
        pages: [MaterialPage<void>(child: widget.child)],
        onDidRemovePage: (_) => setState(() => _shown++),
      ),
    );
  }
}
