import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 내 모임 하나: 제목, 기간과 받는 방식('3.1(월)–3.5(금) · 시간별'), 공개 여부('공개'·'비공개'). 누르면 모임
/// 화면을 위에 연다(뒤로 가면 돌아온다). 고치거나 지우는 것은 모임 설정에서 한다
class MyMeetingTile extends StatelessWidget {
  const MyMeetingTile({super.key, required this.meeting});

  final MeetingRead meeting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiet = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final dates = MeetingDates.range(
      meeting.startDate,
      meeting.endDate,
      excluded: meeting.excludedDates,
    );
    final level = meeting.visibilityLevel;
    final public = level == VisibilityLevel.public;
    return ListTile(
      title: Text(meeting.title),
      subtitle: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${meetingRangeText(dates)} · ${meetingModeLabel(meeting.mode)}',
            style: quiet,
          ),
          if (level != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  public ? Icons.public : Icons.lock_outline,
                  size: 14,
                  color: quiet?.color,
                ),
                const SizedBox(width: 2),
                Text(public ? '공개' : '비공개', style: quiet),
              ],
            ),
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () => context.pushNamed(
        AppRoute.meeting.name,
        pathParameters: {'meetingId': meeting.id},
      ),
    );
  }
}
