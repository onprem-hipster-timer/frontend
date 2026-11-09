import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/theme/app_colors.dart';
import 'package:momeet/shared/ui/theme/app_radius.dart';

/// 알림의 종류. 색만 다르다.
enum AppNoticeKind { info, success, error }

/// 짧은 알림을 띄운다. 이전 알림은 닫는다.
///
/// [context]가 시트·다이얼로그 안이면 그 위에 띄워 가려지지 않게 하고,
/// 아니면 화면의 SnackBar로 띄운다.
void showAppSnackBar(
  BuildContext context,
  String message, {
  AppNoticeKind kind = AppNoticeKind.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  if (ModalRoute.of(context) is PopupRoute) {
    _OverlayNotice.show(
      context,
      message: message,
      kind: kind,
      actionLabel: actionLabel,
      onAction: onAction,
    );
    return;
  }
  ScaffoldMessenger.of(context).showAppSnackBar(
    message,
    kind: kind,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

/// 시트를 닫은 뒤처럼 [BuildContext]가 사라진 다음에도 미리 잡아 둔 messenger로 띄운다.
extension AppSnackBarMessenger on ScaffoldMessengerState {
  void showAppSnackBar(
    String message, {
    AppNoticeKind kind = AppNoticeKind.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final (background, foreground) = _colors(context, kind);
    hideCurrentSnackBar();
    showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: foreground)),
        backgroundColor: background,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: foreground,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}

(Color?, Color?) _colors(BuildContext context, AppNoticeKind kind) {
  final scheme = Theme.of(context).colorScheme;
  return switch (kind) {
    AppNoticeKind.info => (null, null),
    AppNoticeKind.success => (
      AppColors.of(context).success,
      AppColors.of(context).onSuccess,
    ),
    AppNoticeKind.error => (scheme.error, scheme.onError),
  };
}

/// 시트·다이얼로그 위에 띄우는 알림. 같은 오버레이에는 하나만 둔다.
class _OverlayNotice extends StatefulWidget {
  const _OverlayNotice({
    required this.message,
    required this.kind,
    required this.actionLabel,
    required this.onAction,
    required this.onDone,
  });

  final String message;
  final AppNoticeKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDone;

  static final _current = Expando<OverlayEntry>();

  static void show(
    BuildContext context, {
    required String message,
    required AppNoticeKind kind,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _current[overlay]?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _OverlayNotice(
        message: message,
        kind: kind,
        actionLabel: actionLabel,
        onAction: onAction,
        onDone: () {
          if (_current[overlay] == entry) _current[overlay] = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _current[overlay] = entry;
    overlay.insert(entry);
  }

  @override
  State<_OverlayNotice> createState() => _OverlayNoticeState();
}

class _OverlayNoticeState extends State<_OverlayNotice>
    with SingleTickerProviderStateMixin {
  static const _shown = Duration(seconds: 4);

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(_shown, _hide);
  }

  void _hide() {
    if (!mounted) return;
    _controller.reverse().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (background, foreground) = _colors(context, widget.kind);
    final textColor = foreground ?? theme.colorScheme.onInverseSurface;
    final media = MediaQuery.of(context);
    final actionLabel = widget.actionLabel;
    final onAction = widget.onAction;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16 + media.viewInsets.bottom + media.padding.bottom,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) =>
            Opacity(opacity: _controller.value, child: child),
        child: Material(
          color: background ?? theme.colorScheme.inverseSurface,
          elevation: 6,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      widget.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: () {
                      onAction();
                      widget.onDone();
                    },
                    style: TextButton.styleFrom(foregroundColor: textColor),
                    child: Text(actionLabel),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
