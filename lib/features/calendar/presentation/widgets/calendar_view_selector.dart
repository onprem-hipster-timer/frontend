import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_selector_view.dart';

/// 달력 보기(일·주·월·목록) 고르기. 모양은 [CalendarViewSelectorView]
class CalendarViewSelector extends ConsumerWidget {
  const CalendarViewSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(
      calendarSettingsProvider.select((s) => s.viewType),
    );
    return CalendarViewSelectorView(
      current: current,
      onSelected: (view) =>
          ref.read(calendarSettingsProvider.notifier).setViewType(view),
    );
  }
}
