import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/theme/app_radius.dart';

/// 폼 아래의 취소·저장 버튼 줄.
///
/// [onSubmit]이 null이면 저장을 누를 수 없다. [busy]면 두 버튼을 막고 저장 자리에
/// 진행 표시를 둔다. [onCancel]이 없으면 취소는 지금 화면(시트)을 닫는다.
class AppFormActionBar extends StatelessWidget {
  const AppFormActionBar({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.busy = false,
    this.cancelLabel = '취소',
    this.onCancel,
  });

  final String submitLabel;
  final VoidCallback? onSubmit;
  final bool busy;
  final String cancelLabel;
  final VoidCallback? onCancel;

  static final _shape = RoundedRectangleBorder(borderRadius: AppRadius.lgAll);
  static const _padding = EdgeInsets.symmetric(vertical: 16);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: busy
                ? null
                : onCancel ?? () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(padding: _padding, shape: _shape),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: busy ? null : onSubmit,
            style: FilledButton.styleFrom(padding: _padding, shape: _shape),
            child: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(submitLabel),
          ),
        ),
      ],
    );
  }
}
