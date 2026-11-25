import 'package:material_ui/material_ui.dart';

/// 입력 칸 use case의 틀. [texts]를 채운 컨트롤러를 [builder]에 넘기고, [showErrors]면 버튼을 누른 뒤처럼
/// 칸 아래에 검사 결과를 보인다. 칸에 직접 입력해도 그대로 남는다
class FormStage extends StatefulWidget {
  const FormStage({
    super.key,
    required this.texts,
    required this.showErrors,
    required this.builder,
  });

  final List<String> texts;
  final bool showErrors;
  final Widget Function(List<TextEditingController> controllers) builder;

  @override
  State<FormStage> createState() => _FormStageState();
}

class _FormStageState extends State<FormStage> {
  late final _controllers = [
    for (final text in widget.texts) TextEditingController(text: text),
  ];

  @override
  void didUpdateWidget(FormStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (var i = 0; i < _controllers.length; i++) {
      if (widget.texts[i] != oldWidget.texts[i]) {
        _controllers[i].text = widget.texts[i];
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 오류를 끄면 남은 문구까지 지우도록 폼을 새로 만든다
    return Form(
      key: ValueKey(widget.showErrors),
      autovalidateMode: widget.showErrors
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: widget.builder(_controllers),
    );
  }
}

/// 로그인·회원가입 화면처럼 화면 바탕 위 좌우 24 여백에 폭을 꽉 채워 둔다
Widget authScreenFrame(Widget child) =>
    SingleChildScrollView(padding: const EdgeInsets.all(24), child: child);
