import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_names.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 이 모임에서 보일 내 이름 입력. [currentName]으로 채워 열고, 이름이 맞으면 [onSubmit]에 넘긴다
class MeetingNameSheetView extends StatefulWidget {
  const MeetingNameSheetView({
    super.key,
    required this.currentName,
    required this.busy,
    required this.onSubmit,
  });

  final String currentName;

  /// 보내는 중. 그동안은 다시 보내지 않는다
  final bool busy;
  final ValueChanged<String> onSubmit;

  @override
  State<MeetingNameSheetView> createState() => _MeetingNameSheetViewState();
}

class _MeetingNameSheetViewState extends State<MeetingNameSheetView> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.busy) return;
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(_name.text);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: '내 닉네임',
      formKey: _formKey,
      actions: AppFormActionBar(
        submitLabel: '저장',
        onSubmit: _submit,
        busy: widget.busy,
      ),
      children: [
        TextFormField(
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '이 ${Terms.meeting}에서 보일 닉네임',
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          validator: (value) => meetingNameError(value ?? ''),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}
