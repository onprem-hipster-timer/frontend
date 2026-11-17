import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slot_card.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// '추천 시간': 두 명 이상 함께 되는 이어진 시간 카드와 정렬 고르기(기본 인원 많은 순).
///
/// [onAddToCalendar]가 없으면(게스트는 달력이 없다) 카드에 '내 달력에 일정 만들기'가 없다. [fill]이면 받은
/// 높이를 채우고 제목 줄은 둔 채 카드 목록만 상자 안에서 굴린다(넓은 화면 옆 칸).
class MeetingSlotsPanel extends StatefulWidget {
  const MeetingSlotsPanel({
    super.key,
    required this.board,
    required this.onAddToCalendar,
    this.fill = false,
  });

  final MeetingBoard board;
  final ValueChanged<MeetingRun>? onAddToCalendar;
  final bool fill;

  @override
  State<MeetingSlotsPanel> createState() => _MeetingSlotsPanelState();
}

class _MeetingSlotsPanelState extends State<MeetingSlotsPanel> {
  var _order = MeetingRunOrder.people;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    final scheme = Theme.of(context).colorScheme;
    final runs = board.runs(_order);
    final Widget list = runs.isEmpty
        ? Text(
            '두 명 이상 함께 되는 시간이 생기면 여기에 추천해 드려요',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          )
        : _RunList(
            board: board,
            runs: runs,
            onAddToCalendar: widget.onAddToCalendar,
          );
    return MeetingPanel(
      title: '추천 시간',
      help: '여러 사람이 함께 되는 시간을 인원과 길이 순으로 보여 줘요',
      color: scheme.primaryContainer,
      foreground: scheme.onPrimaryContainer,
      fill: widget.fill,
      trailing: _OrderMenu(
        mode: board.grid.mode,
        value: _order,
        onChanged: (order) => setState(() => _order = order),
      ),
      child: widget.fill
          ? Scrollbar(
              controller: _scroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scroll,
                // 막대가 카드를 가리지 않게 오른쪽을 띄운다
                padding: const EdgeInsets.only(right: 12, bottom: 4),
                child: list,
              ),
            )
          : list,
    );
  }
}

/// 카드 목록. 카드가 [_minCardWidth]보다 좁아지지 않게 한 줄의 카드 수를 정한다
class _RunList extends StatelessWidget {
  const _RunList({
    required this.board,
    required this.runs,
    required this.onAddToCalendar,
  });

  final MeetingBoard board;
  final List<MeetingRun> runs;
  final ValueChanged<MeetingRun>? onAddToCalendar;

  static const _minCardWidth = 168.0;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.max(
          1,
          ((constraints.maxWidth + _gap) / (_minCardWidth + _gap)).floor(),
        );
        final width = (constraints.maxWidth - _gap * (columns - 1)) / columns;
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
                  onAddToCalendar: switch (onAddToCalendar) {
                    final add? => () => add(run),
                    null => null,
                  },
                ),
              ),
          ],
        );
      },
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
  final VoidCallback? onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final text = meetingRunText(board.grid, run);
    final unavailable = board.unavailableIn(run);
    return MeetingSlotCard(
      title: text.title,
      detail: text.detail,
      people: [
        for (final participant in board.participants)
          if (run.people.contains(participant.id))
            (
              name: participant.displayName,
              owner: participant.isOwner,
              guest: participant.isGuest,
              self: board.isSelf(participant.id),
            ),
        if (run.people.contains(MeetingBoard.pendingSelfId))
          (name: board.selfName, owner: false, guest: false, self: true),
      ],
      unavailable: [
        for (final participant in board.participants)
          if (unavailable.contains(participant.id)) participant.displayName,
        if (unavailable.contains(MeetingBoard.pendingSelfId)) board.selfName,
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
