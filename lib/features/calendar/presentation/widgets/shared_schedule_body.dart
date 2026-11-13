import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_detail_info.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_title.dart';
import 'package:momeet/features/visibility/presentation/widgets/shared_notice.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 다른 사람이 공유한 일정 [schedule]의 상세. 공유한 사람과 일정 정보만 보이고 고칠 수 없다
class SharedScheduleBody extends StatelessWidget {
  const SharedScheduleBody({super.key, required this.schedule});

  final ScheduleRead schedule;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScheduleTitle(title: schedule.title),
          const SizedBox(height: 24),
          SharedNotice(
            ownerId: schedule.ownerId,
            message: '공유받은 일정이라 보기만 할 수 있습니다',
          ),
          const SizedBox(height: 16),
          ScheduleDetailInfo(schedule: schedule),
        ],
      ),
    );
  }
}
