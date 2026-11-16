import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_chip.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';

/// '일정 참여자': 참여자 이름 칩(주인은 왕관)과 내 이름을 바꾸는 '편집'
class MeetingParticipantsPanel extends StatelessWidget {
  const MeetingParticipantsPanel({
    super.key,
    required this.board,
    required this.onEdit,
  });

  final MeetingBoard board;

  /// 내 이름 바꾸기. 아직 참여하지 않았으면 '편집'을 두지 않는다
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final participants = board.participants;
    return MeetingPanel(
      title: '일정 참여자',
      trailing: board.me == null
          ? null
          : TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('편집'),
            ),
      child: participants.isEmpty
          ? Text(
              '아직 참여한 사람이 없습니다. 내 시간을 칠하면 참여합니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final participant in participants)
                  MeetingNameChip(
                    name: participant.displayName,
                    owner: board.isOwner(participant),
                    self: board.isSelf(participant.id),
                  ),
              ],
            ),
    );
  }
}
