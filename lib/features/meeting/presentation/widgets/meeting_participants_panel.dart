import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_chip.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// '일정 참여자': 참여자 이름 칩(주인은 왕관)과 '편집'.
///
/// 모임 주인의 '편집'은 칩마다 빼기 단추를, 내 칩에는 이름 바꾸기 단추를 두고 '완료'로 닫는다.
/// 다른 사람의 '편집'은 바로 내 닉네임 바꾸기를 연다(참여했을 때만 둔다).
class MeetingParticipantsPanel extends StatefulWidget {
  const MeetingParticipantsPanel({
    super.key,
    required this.board,
    required this.onRename,
    required this.onRemove,
  });

  final MeetingBoard board;

  /// 내 닉네임 바꾸기. 없으면 다른 사람의 '편집'이 없다
  final VoidCallback? onRename;

  /// 주인이 참여자를 뺀다
  final ValueChanged<ParticipantRead> onRemove;

  @override
  State<MeetingParticipantsPanel> createState() =>
      _MeetingParticipantsPanelState();
}

class _MeetingParticipantsPanelState extends State<MeetingParticipantsPanel> {
  var _editing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final board = widget.board;
    final participants = board.participants;
    final owner = board.ownedByMe;
    final editing = _editing && owner && participants.isNotEmpty;
    return MeetingPanel(
      title: '일정 참여자',
      trailing: owner
          ? participants.isEmpty
                ? null
                : TextButton.icon(
                    onPressed: () => setState(() => _editing = !editing),
                    icon: Icon(
                      editing ? Icons.check : Icons.edit_outlined,
                      size: 16,
                    ),
                    label: Text(editing ? '완료' : '편집'),
                  )
          : board.me == null || widget.onRename == null
          ? null
          : TextButton.icon(
              onPressed: widget.onRename,
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
                    owner: participant.isOwner,
                    guest: participant.isGuest,
                    self: board.isSelf(participant.id),
                    onRemove: editing && !board.isSelf(participant.id)
                        ? () => widget.onRemove(participant)
                        : null,
                    onRename: editing && board.isSelf(participant.id)
                        ? widget.onRename
                        : null,
                  ),
              ],
            ),
    );
  }
}
