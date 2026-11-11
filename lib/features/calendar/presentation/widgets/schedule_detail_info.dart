import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/features/calendar/presentation/utils/schedule_formatters.dart';
import 'package:momeet/features/calendar/presentation/widgets/info_row.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 시간·설명·태그·상태·반복·생성 시각
class ScheduleDetailInfo extends StatelessWidget {
  static final _createdAtFormat = DateFormat('yyyy.MM.dd HH:mm');

  const ScheduleDetailInfo({super.key, required this.schedule});

  final ScheduleRead schedule;

  @override
  Widget build(BuildContext context) {
    final statusColor = getScheduleStatusColor(context, schedule.state);
    final statusText = getScheduleStatusText(schedule.state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoRow(
          icon: Icons.access_time,
          label: '시간',
          value: formatScheduleTime(schedule),
        ),
        if (schedule.description != null &&
            schedule.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          InfoRow(
            icon: Icons.description,
            label: '설명',
            value: schedule.description!,
            isMultiline: true,
          ),
        ],
        if (schedule.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          _TagsSection(tags: schedule.tags.toList()),
        ],
        const SizedBox(height: 16),
        InfoRow(
          icon: Icons.flag,
          label: '상태',
          valueWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.lgAll,
            ),
            child: Text(
              statusText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (schedule.recurrenceRule != null) ...[
          const SizedBox(height: 16),
          InfoRow(
            icon: Icons.repeat,
            label: '반복',
            value: parseRecurrenceRule(schedule.recurrenceRule!),
          ),
        ],
        const SizedBox(height: 16),
        InfoRow(
          icon: Icons.schedule,
          label: '생성',
          value: _createdAtFormat.format(schedule.createdAt.toLocal()),
        ),
      ],
    );
  }
}

/// 일정에 붙은 태그 칩들
class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.tags});

  final List<TagRead> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.label,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              '태그',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final tag in tags) _TagChip(tag: tag)],
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final TagRead tag;

  @override
  Widget build(BuildContext context) {
    final color = HexColor.fromHex(tag.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        tag.name,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
