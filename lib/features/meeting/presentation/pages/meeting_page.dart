import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_autosave.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_participant_removal.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_schedule.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_grid.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_help_icon.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_sheet.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_participants_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_save_indicator.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_timezone_label.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 화면. 공유 링크(`/meetings/<id>`)로 열고, 탭 셸 밖에 있다.
///
/// 넓으면 왼쪽에 내 시간 격자, 오른쪽에 링크·일정 참여자·선택된 일정을 둔다. 좁으면 격자 → 선택된 일정 →
/// 일정 참여자 → 링크 순서로 쌓는다(칠하기가 이 화면의 일이고, 그 결과가 바로 아래에 보이게).
class MeetingPage extends ConsumerWidget {
  const MeetingPage({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = meetingBoardProvider(meetingId);
    final state = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? null
            : IconButton(
                icon: const Icon(Icons.home_outlined),
                tooltip: '처음 화면으로',
                onPressed: () => context.goNamed(AppRoute.calendar.name),
              ),
        title: Text(state.value?.board.meeting.title ?? Terms.meeting),
      ),
      body: state.when(
        data: (state) {
          final board = state.board;
          final notifier = ref.read(provider.notifier);
          return _MeetingLayout(
            availability: _AvailabilitySection(
              state: state,
              onPaint: notifier.paint,
              onRetry: notifier.retrySave,
            ),
            slots: MeetingSlotsPanel(
              board: board,
              onAddToCalendar: (run) =>
                  addMeetingRunToCalendar(context, board, run),
            ),
            participants: MeetingParticipantsPanel(
              board: board,
              onRename: () => showMeetingNameSheet(
                context,
                meetingId: meetingId,
                currentName: board.me?.displayName ?? board.selfName,
              ),
              onRemove: (participant) => removeMeetingParticipant(
                context,
                ref,
                meetingId,
                participant,
              ),
            ),
            link: MeetingLinkPanel(meetingId: meetingId),
          );
        },
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorState(
          title: '${Terms.meeting.withJosa('을', '를')} 불러오지 못했습니다',
          error: error,
          onRetry: () {
            ref.invalidate(meetingProvider(meetingId));
            ref.invalidate(provider);
          },
        ),
      ),
    );
  }
}

/// 넓으면 격자 옆에 상자들, 좁으면 위에서 아래로
class _MeetingLayout extends StatelessWidget {
  const _MeetingLayout({
    required this.availability,
    required this.slots,
    required this.participants,
    required this.link,
  });

  /// 이 폭부터 두 칸
  static const _twoColumnsFrom = 840.0;
  static const _sideWidth = 380.0;

  final Widget availability;
  final Widget slots;
  final Widget participants;
  final Widget link;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _twoColumnsFrom) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                availability,
                const SizedBox(height: 24),
                slots,
                const SizedBox(height: 12),
                participants,
                const SizedBox(height: 12),
                link,
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: availability),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: _sideWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        link,
                        const SizedBox(height: 16),
                        participants,
                        const SizedBox(height: 16),
                        slots,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// '내 시간 선택하기': 제목 줄(시간별이면 하루 범위, 도움말, 저장 상태), 시간 기준, 격자
class _AvailabilitySection extends StatelessWidget {
  const _AvailabilitySection({
    required this.state,
    required this.onPaint,
    required this.onRetry,
  });

  final MeetingBoardState state;
  final MeetingPaint onPaint;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meeting = state.board.meeting;
    final touch = switch (theme.platform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => true,
      _ => false,
    };
    final caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Semantics(
              header: true,
              child: Text(
                '내 시간 선택하기',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (state.board.grid.mode == MeetingMode.hourly)
              _RangeChip(meetingHoursText(meeting)),
            MeetingHelpIcon(
              touch
                  ? '칸을 누르면 칠하거나 지웁니다. 길게 누른 채 끌면 여러 칸을 한 번에 칠하고, '
                        '칠한 칸에서 시작하면 지웁니다. 칠하면 바로 저장됩니다.'
                  : '칸을 누르거나 누른 채 끌어서 칠합니다. 칠한 칸에서 시작하면 지웁니다. '
                        '칠하면 바로 저장됩니다.',
            ),
            MeetingSaveIndicator(status: state.status, onRetry: onRetry),
          ],
        ),
        const SizedBox(height: 4),
        MeetingTimezoneLabel(meeting.timezone),
        if (state.status == MeetingSaveStatus.idle) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                touch ? Icons.touch_app_outlined : Icons.mouse_outlined,
                size: 16,
                color: caption?.color,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  touch ? '길게 누른 채 끌면 여러 칸을 칠합니다' : '누른 채 끌면 여러 칸을 칠합니다',
                  style: caption,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        MeetingAvailabilityGrid(shading: state.board, onPaint: onPaint),
      ],
    );
  }
}

/// 시간별 하루 범위 알약
class _RangeChip extends StatelessWidget {
  const _RangeChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.pillAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Text(text, style: theme.textTheme.labelMedium),
      ),
    );
  }
}
