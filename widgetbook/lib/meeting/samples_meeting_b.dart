import 'package:material_ui/material_ui.dart';

/// 누르면 값이 바뀌어야 하는 위젯(질문·폼)이 카탈로그에서도 반응하도록 값을 들고 있다. knob이 바뀌면 [key]를
/// 바꿔 [initial]부터 다시 시작한다
class MeetingSampleHolder<T> extends StatefulWidget {
  const MeetingSampleHolder({
    super.key,
    required this.initial,
    required this.builder,
  });

  final T initial;
  final Widget Function(T value, ValueChanged<T> onChanged) builder;

  @override
  State<MeetingSampleHolder<T>> createState() => _MeetingSampleHolderState<T>();
}

class _MeetingSampleHolderState<T> extends State<MeetingSampleHolder<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (value) => setState(() => _value = value));
}
