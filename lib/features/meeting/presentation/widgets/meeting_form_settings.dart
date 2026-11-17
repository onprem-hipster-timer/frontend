import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_edit.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_choice_row.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_field_refusal.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_mode_selector.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_section_title.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_shake.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_time_range.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_timezone_label.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 펼친 모임 만들기 폼의 설정: '모임 시간'(받는 방식, 시간별 하루 범위, 시간 기준)과 '공개 여부'(공개가 아니면 그 아래
/// [access])·'게스트 로그인'.
/// 공개가 아니면 게스트 로그인을 고를 수 없다. 값이 규칙에 걸려 저절로 바뀐 자리는 [modeShakes]·[guestShakes]가
/// 늘 때 떤다. 모임 설정에서 서버가 거절한 것은 그 자리 아래에 [refusals]의 말로 알린다
class MeetingFormSettings extends StatelessWidget {
  const MeetingFormSettings({
    super.key,
    required this.draft,
    required this.timezone,
    required this.modeShakes,
    required this.guestShakes,
    required this.onChanged,
    required this.onPublicChanged,
    this.access,
    this.refusals = const {},
  });

  final MeetingDraft draft;

  /// 아직 모르면 null
  final String? timezone;

  final int modeShakes;
  final int guestShakes;
  final ValueChanged<MeetingDraft> onChanged;
  final ValueChanged<bool> onPublicChanged;

  /// 공개가 아닐 때 '공개 여부' 아래에 두는 참여할 사람 칸
  final Widget? access;

  /// 모임 설정에서 서버가 거절한 것과 그 까닭(방식·시간, 공개 범위, 게스트 로그인 자리)
  final Map<MeetingEditPart, String> refusals;

  @override
  Widget build(BuildContext context) {
    final draft = this.draft;
    final visibilityRefusal = refusals[MeetingEditPart.visibility];
    final guestRefusal = refusals[MeetingEditPart.guests];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimeSettings(
          draft: draft,
          timezone: timezone,
          modeShakes: modeShakes,
          refusal:
              refusals[MeetingEditPart.mode] ?? refusals[MeetingEditPart.time],
          onChanged: onChanged,
        ),
        const SizedBox(height: 24),
        MeetingSectionTitle(
          '공개 여부',
          help:
              '허용하면 링크가 있는 누구나 이 ${Terms.meeting.withJosa('을', '를')} 볼 수 있습니다. '
              '비허용이면 나만 볼 수 있습니다.',
        ),
        MeetingChoiceRow(
          label: '공개 여부',
          value: draft.isPublic,
          onChanged: onPublicChanged,
        ),
        if (!draft.isPublic && access != null) ...[
          const SizedBox(height: 12),
          access!,
        ],
        if (visibilityRefusal != null) MeetingFieldRefusal(visibilityRefusal),
        const SizedBox(height: 16),
        const MeetingSectionTitle(
          '게스트 로그인',
          help:
              '허용하면 회원이 아니어도 닉네임과 비밀번호로 참여할 수 있습니다. '
              '공개 ${Terms.meeting}에서만 허용할 수 있습니다.',
        ),
        MeetingShake(
          count: guestShakes,
          child: MeetingChoiceRow(
            label: '게스트 로그인',
            value: draft.allowGuests,
            onChanged: draft.isPublic
                ? (value) => onChanged(draft.withGuests(value))
                : null,
          ),
        ),
        if (guestRefusal != null) MeetingFieldRefusal(guestRefusal),
      ],
    );
  }
}

/// '모임 시간': 받는 방식, 시간별 하루 범위, 거절된 까닭, 시간 기준
class _TimeSettings extends StatelessWidget {
  const _TimeSettings({
    required this.draft,
    required this.timezone,
    required this.modeShakes,
    required this.refusal,
    required this.onChanged,
  });

  final MeetingDraft draft;
  final String? timezone;
  final int modeShakes;
  final String? refusal;
  final ValueChanged<MeetingDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = this.draft;
    final timezone = this.timezone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MeetingSectionTitle(
          '${Terms.meeting} 시간',
          caption: '최대 범위 설정',
          help:
              '참여자가 가능한 시간을 고를 범위입니다. '
              '시간별은 $hourlyMaxDays일 이하 날짜의 하루 시간 범위를, 날짜별은 날짜만, '
              '요일별은 한 주의 요일만 받습니다.',
        ),
        const SizedBox(height: 4),
        MeetingShake(
          count: modeShakes,
          child: MeetingModeSelector(
            mode: draft.mode,
            hourlyEnabled: draft.hourlyAvailable,
            onChanged: (mode) => onChanged(draft.withMode(mode)),
          ),
        ),
        Text(
          meetingHourlyRule,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (draft.mode == MeetingMode.hourly) ...[
          const SizedBox(height: 12),
          MeetingTimeRange(
            startHour: draft.startHour,
            endHour: draft.endHour,
            onStartChanged: (hour) => onChanged(draft.withStartHour(hour)),
            onEndChanged: (hour) => onChanged(draft.withEndHour(hour)),
          ),
        ],
        if (refusal case final text?) MeetingFieldRefusal(text),
        if (timezone != null) ...[
          const SizedBox(height: 12),
          MeetingTimezoneLabel(timezone),
        ],
      ],
    );
  }
}
