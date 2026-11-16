import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slot_card.dart';

/// '선택된 일정': 두 명 이상 되는 이어진 시간 카드와 정렬 고르기(기본 인원 많은 순)
class MeetingSlotsPanel extends StatefulWidget {
  const MeetingSlotsPanel({
    super.key,
    required this.board,
    required this.onAddToCalendar,
  });

  final MeetingBoard board;
  final ValueChanged<MeetingRun> onAddToCalendar;

  @override
  State<MeetingSlotsPanel> createState() => _MeetingSlotsPanelState();
}

class _MeetingSlotsPanelState extends State<MeetingSlotsPanel> {
  var _order = MeetingRunOrder.people;

  /// 카드가 이보다 좁아지지 않게 한 줄의 카드 수를 정한다
  static const _minCardWidth = 168.0;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    final scheme = Theme.of(context).colorScheme;
    final runs = board.runs(_order);
    return MeetingPanel(
      title: '선택된 일정',
      color: scheme.primaryContainer,
      foreground: scheme.onPrimaryContainer,
      trailing: _OrderMenu(
        mode: board.grid.mode,
        value: _order,
        onChanged: (order) => setState(() => _order = order),
      ),
      child: runs.isEmpty
          ? Text(
              '두 명 이상 되는 시간이 겹치면 여기에 보입니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = math.max(
                  1,
                  ((constraints.maxWidth + _gap) / (_minCardWidth + _gap))
                      .floor(),
                );
                final width =
                    (constraints.maxWidth - _gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: _gap,
                  runSpacing: _gap,
                  children: [
                    for (final run in runs)
                      SizedBox(
                        width: width,
                        child: _RunCard(
                          key: ValueKey(run.first.index),
                          board: board,
                          run: run,
                          onAddToCalendar: () => widget.onAddToCalendar(run),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

/// 묶음 하나의 카드: 이름은 참여자 순서(주인이 앞)이고, 참여하기 전의 나는 맨 뒤다
class _RunCard extends StatelessWidget {
  const _RunCard({
    super.key,
    required this.board,
    required this.run,
    required this.onAddToCalendar,
  });

  final MeetingBoard board;
  final MeetingRun run;
  final VoidCallback onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final text = meetingRunText(board.grid, run);
    return MeetingSlotCard(
      title: text.title,
      detail: text.detail,
      people: [
        for (final participant in board.participants)
          if (run.people.contains(participant.id))
            (
              name: participant.displayName,
              owner: board.isOwner(participant),
              self: board.isSelf(participant.id),
            ),
        if (run.people.contains(MeetingBoard.pendingSelfId))
          (name: board.selfName, owner: false, self: true),
      ],
      onAddToCalendar: onAddToCalendar,
    );
  }
}

/// 정렬 고르기. 방식마다 날짜·길이를 부르는 말이 다르다
class _OrderMenu extends StatelessWidget {
  const _OrderMenu({
    required this.mode,
    required this.value,
    required this.onChanged,
  });

  final MeetingMode mode;
  final MeetingRunOrder value;
  final ValueChanged<MeetingRunOrder> onChanged;

  static const _orders = [
    MeetingRunOrder.people,
    MeetingRunOrder.date,
    MeetingRunOrder.length,
  ];

  String _label(MeetingRunOrder order) => switch (order) {
    MeetingRunOrder.date => mode == MeetingMode.weekly ? '요일 순' : '날짜 순',
    MeetingRunOrder.people => '인원 많은 순',
    MeetingRunOrder.length => mode == MeetingMode.hourly ? '시간 긴 순' : '기간 긴 순',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonHideUnderline(
      child: DropdownButton<MeetingRunOrder>(
        value: value,
        isDense: true,
        borderRadius: BorderRadius.circular(12),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        selectedItemBuilder: (context) => [
          for (final order in _orders)
            Center(
              child: Text(
                _label(order),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
        iconEnabledColor: theme.colorScheme.onPrimaryContainer,
        items: [
          for (final order in _orders)
            DropdownMenuItem(value: order, child: Text(_label(order))),
        ],
        onChanged: (order) {
          if (order != null) onChanged(order);
        },
      ),
    );
  }
}
