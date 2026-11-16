import 'package:material_ui/material_ui.dart';

/// 물음표. 누르거나 마우스를 올리면 [message]를 띄운다
class MeetingHelpIcon extends StatelessWidget {
  const MeetingHelpIcon(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.help_outline,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
