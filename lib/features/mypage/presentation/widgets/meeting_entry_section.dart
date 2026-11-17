import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 모임 만들기로 가는 항목. 모임은 탭이 아니라 독립 화면이라 앱 안에서는 여기서 연다
class MeetingEntrySection extends StatelessWidget {
  const MeetingEntrySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.groups_outlined,
          color: theme.colorScheme.onSurface,
        ),
        title: const Text('${Terms.meeting} 만들기'),
        subtitle: Text(
          '날짜를 골라 링크 하나로 모두의 시간을 모아요',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () => context.pushNamed(AppRoute.meetings.name),
      ),
    );
  }
}
