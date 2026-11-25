import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 이 화면을 보는 동안 브라우저 탭 제목을 [title]로 한다.
///
/// 앱(MaterialApp)의 [Title]은 제목이 바뀔 때만 다시 알리므로, 이 화면을 떠나거나 위에 다른 화면이 열리면 앱의
/// 제목으로 되돌린다. 그 사이 다른 [PageTitle]이 제목을 정했으면 그대로 둔다.
///
/// 테스트: test/core/title/page_title_test.dart
class PageTitle extends StatefulWidget {
  const PageTitle({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  State<PageTitle> createState() => _PageTitleState();
}

class _PageTitleState extends State<PageTitle> {
  /// 지금 탭 제목을 정한 화면
  static _PageTitleState? _owner;

  /// 되돌릴 앱의 제목과 색
  Title? _app;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = context.findAncestorWidgetOfExactType<Title>();
    _update();
  }

  @override
  void didUpdateWidget(PageTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) _update();
  }

  @override
  void dispose() {
    if (identical(_owner, this)) _restore();
    super.dispose();
  }

  void _update() {
    if (ModalRoute.isCurrentOf(context) ?? true) {
      _owner = this;
      _send(widget.title);
    } else if (identical(_owner, this)) {
      _restore();
    }
  }

  void _restore() {
    _owner = null;
    final app = _app;
    if (app != null) _send(app.title);
  }

  void _send(String label) {
    final color = _app?.color;
    if (color == null) return;
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(
        label: label,
        primaryColor: color.toARGB32(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
