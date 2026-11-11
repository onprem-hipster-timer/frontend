import 'package:material_ui/material_ui.dart';

/// 하단 시트 안의 폼 틀. 제목, 칸들(사이 간격 20), 아래 버튼 줄을 차례로 두고 굴릴 수 있게 한다.
///
/// [showAppSheet]의 builder로 쓴다. 검사가 필요하면 [formKey]를 넘긴다.
class AppFormSheet extends StatelessWidget {
  const AppFormSheet({
    super.key,
    required this.title,
    required this.children,
    required this.actions,
    this.formKey,
  });

  final String title;
  final List<Widget> children;

  /// 보통 [AppFormActionBar]
  final Widget actions;
  final GlobalKey<FormState>? formKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 20,
                children: children,
              ),
              const SizedBox(height: 32),
              actions,
            ],
          ),
        ),
      ),
    );
  }
}
