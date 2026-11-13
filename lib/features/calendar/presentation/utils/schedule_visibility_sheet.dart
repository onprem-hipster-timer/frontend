import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/features/visibility/data/rest_resource_visibility.dart';
import 'package:momeet/features/visibility/presentation/widgets/visibility_button.dart';
import 'package:momeet/features/visibility/presentation/widgets/visibility_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/providers/api_providers.dart';

/// 내 일정 [schedule]의 공유 설정 시트를 연다. 저장하면 일정 상세와 캘린더를 다시 읽는다
///
/// 할 일 마감으로 만든 일정은 할 일의 내용이 일정에 담겨 함께 보인다고 알린다.
///
/// 테스트: test/features/calendar/presentation/pages/schedule_detail_visibility_test.dart
Future<void> showScheduleVisibilitySheet(
  BuildContext context,
  ScheduleRead schedule,
) {
  final container = ProviderScope.containerOf(context, listen: false);
  return showVisibilitySheet(
    context,
    target: RestResourceVisibility(
      container.read(visibilityApiProvider),
      ResourceType.schedule,
      schedule.id,
    ),
    levels: resourceVisibilityLevels,
    notice: schedule.sourceTodoId == null
        ? null
        : '${Terms.todo}의 마감으로 만든 일정이라 ${Terms.todo}의 제목·설명·태그·마감 시각도 '
              '함께 보입니다. ${Terms.todo} 자체는 따로 공유해야 보입니다.',
    onSaved: (container) async {
      container.invalidate(scheduleDetailProvider(schedule.id));
      container.invalidate(currentSchedulesProvider);
    },
  );
}
