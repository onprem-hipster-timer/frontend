import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_brush_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_question_prompt.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_shake.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// '어떻게 받을까요?': 시간별·날짜별·요일별을 한 줄 설명과 함께 놓는다. 미리 고른 방식은 없고, 다시 묻는
/// 질문이면 지금 방식([chosen])을 채운다. 시간별을 받을 수 없으면([hourlyAvailable]이 false) 흐리게 두고
/// 까닭을 적으며, 누르면 떨고 까닭을 스크린 리더에 알린다
class MeetingModeQuestion extends StatefulWidget {
  const MeetingModeQuestion({
    super.key,
    required this.hourlyAvailable,
    required this.onChoose,
    this.chosen,
  });

  final bool hourlyAvailable;
  final ValueChanged<MeetingMode> onChoose;
  final MeetingMode? chosen;

  @override
  State<MeetingModeQuestion> createState() => _MeetingModeQuestionState();
}

class _MeetingModeQuestionState extends State<MeetingModeQuestion> {
  /// 고를 수 없는 시간별을 누른 횟수
  var _refusals = 0;

  static const _icons = {
    MeetingMode.hourly: Icons.table_chart_outlined,
    MeetingMode.daily: Icons.calendar_today_outlined,
    MeetingMode.weekly: Icons.calendar_view_week_outlined,
  };

  void _refuse() {
    setState(() => _refusals++);
    SemanticsService.sendAnnouncement(
      View.of(context),
      meetingHourlyUnavailable,
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MeetingQuestionPrompt(headline: meetingModeQuestion),
        const SizedBox(height: 16),
        for (final mode in MeetingMode.$valuesDefined) ...[
          if (mode != MeetingMode.hourly) const SizedBox(height: 8),
          if (mode == MeetingMode.hourly && !widget.hourlyAvailable)
            MeetingShake(
              count: _refusals,
              child: _ModeTile(
                icon: _icons[mode]!,
                mode: mode,
                description: meetingHourlyUnavailable,
                enabled: false,
                chosen: false,
                onTap: _refuse,
              ),
            )
          else
            _ModeTile(
              icon: _icons[mode]!,
              mode: mode,
              description: meetingModeDescription(mode),
              enabled: true,
              chosen: mode == widget.chosen,
              onTap: () => widget.onChoose(mode),
            ),
        ],
      ],
    );
  }
}

/// 방식 하나: 아이콘, 이름, 한 줄 설명. 고를 수 없으면 흐리지만 누를 수는 있다(까닭을 알린다)
class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.mode,
    required this.description,
    required this.enabled,
    required this.chosen,
    required this.onTap,
  });

  final IconData icon;
  final MeetingMode mode;
  final String description;
  final bool enabled;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ink = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.4);
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: chosen ? true : null,
        enabled: enabled,
        child: Material(
          color: chosen
              ? scheme.secondaryContainer
              : scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lgAll,
            side: chosen
                ? BorderSide(color: scheme.primary, width: 1.5)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: enabled ? scheme.primary : ink),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meetingModeLabel(mode),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          keepWords(description),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: enabled ? scheme.onSurfaceVariant : ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
