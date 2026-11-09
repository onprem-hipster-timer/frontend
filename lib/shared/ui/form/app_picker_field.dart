import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/theme/app_radius.dart';

/// 누르면 선택 창(날짜·시간·목록 등)을 여는 입력 칸.
///
/// 입력 칸과 같은 테두리·이름표로 [value]를 보이고, 비었으면 [placeholder]를 보인다.
/// [onClear]를 주면 값이 있을 때 지우기 버튼을, 아니면 펼침 화살표를 둔다.
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.placeholder,
    this.onClear,
    this.errorText,
  });

  final String label;
  final String? value;

  /// null이면 누를 수 없다.
  final VoidCallback? onTap;
  final IconData? icon;
  final String? placeholder;
  final VoidCallback? onClear;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    final onClear = this.onClear;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: InputDecorator(
        isEmpty: value == null && placeholder == null,
        decoration: InputDecoration(
          labelText: label,
          enabled: onTap != null,
          errorText: errorText,
          prefixIcon: icon == null ? null : Icon(icon),
          suffixIcon: value != null && onClear != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: '$label 지우기',
                  onPressed: onClear,
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          value ?? placeholder ?? '',
          style: value == null
              ? TextStyle(color: Theme.of(context).hintColor)
              : null,
        ),
      ),
    );
  }
}
