import 'package:material_ui/material_ui.dart';

/// 높이가 정해진 곳에서는 가운데 두고 칸보다 길면 굴리고, 아니면 내용 높이로 그린다.
class AppStateFrame extends StatelessWidget {
  const AppStateFrame({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedHeight
          ? Center(child: SingleChildScrollView(child: content))
          : Center(child: content),
    );
  }
}
