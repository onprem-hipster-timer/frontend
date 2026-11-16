import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 첫날을 보이는 탁상 달력 그림. 날짜를 아직 모르면 비워 둔다
class MeetingDateBadge extends StatelessWidget {
  const MeetingDateBadge({super.key, required this.day});

  final DateTime? day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final day = this.day;
    return Semantics(
      label: day == null ? null : '첫날 ${meetingDayLabel(day)}',
      excludeSemantics: true,
      child: IntrinsicWidth(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 140),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: AppRadius.xlAll,
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Binding(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      Text(
                        day == null ? ' ' : '${day.day}',
                        style: theme.textTheme.displayMedium,
                      ),
                      Text(
                        day == null ? ' ' : meetingMonthName(day),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 달력 윗부분의 띠와 고리
class _Binding extends StatelessWidget {
  const _Binding();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < 4; i++)
              SizedBox(
                width: 6,
                height: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.onTertiaryContainer,
                    borderRadius: AppRadius.pillAll,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
