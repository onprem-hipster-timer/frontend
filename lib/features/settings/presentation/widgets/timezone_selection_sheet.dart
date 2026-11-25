// Timezone Selection Bottom Sheet
//
// 사용자가 타임존을 선택할 수 있는 모달 바텀 시트
// IANA 타임존 DB에서 전체 목록을 표시하며 검색 필터를 제공합니다.

import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/features/settings/presentation/widgets/timezone_selection_sheet_view.dart';

/// 타임존 선택 바텀 시트. 고르면 저장하고 닫는다. 모양은 [TimezoneSelectionSheetView]
class TimezoneSelectionSheet extends ConsumerWidget {
  const TimezoneSelectionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TimezoneSelectionSheetView(
      currentTimezone: ref.watch(timezoneProvider).value ?? defaultTimezone,
      onSelected: (timezone) async {
        await ref.read(timezoneProvider.notifier).updateTimezone(timezone);
        if (context.mounted) context.pop();
      },
    );
  }
}

/// 타임존 선택 시트를 표시하는 헬퍼 함수
///
/// useRootNavigator: true 옵션을 사용하여 네비게이션 바 딤 이슈를 방지합니다.
Future<void> showTimezoneSelectionSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    builder: (context) => const TimezoneSelectionSheet(),
  );
}
