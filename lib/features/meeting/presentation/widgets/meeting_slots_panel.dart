import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_run_copy.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_run_highlight.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slot_card.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// '추천 시간': 두 명 이상 함께 되는 이어진 시간 카드와 정렬 고르기(기본 모모밋 추천).
///
/// [onAddToCalendar]가 없으면(게스트는 달력이 없다) 카드에 '내 달력에 일정 만들기'가 없다. [fill]이면 받은
/// 높이를 채우고 제목 줄은 둔 채 카드 목록만 상자 안에서 굴린다(넓은 화면 옆 칸).
///
/// 카드마다 '복사'가 그 카드를 글로 복사하고([meetingRunCopyText]), 제목 줄의 '모두 복사'는 모임 제목과
/// [link] 아래에 지금 순서의 카드를 번호와 함께 복사한다.
///
/// 카드에 마우스를 올리거나 누르면 [highlight]에 알려 격자의 그 칸을 강조한다. 누른 카드는 고정되어 이름을
/// 펼치고, 고정은 한 번에 하나다. 고정한 카드가 목록에서 없어지면 고정을 푼다. 격자를 끌어 칠하는 동안은
/// 상자가 마우스·누르기·휠을 받지 않는다(카드는 저장한 뒤에 바뀐다).
class MeetingSlotsPanel extends StatefulWidget {
  const MeetingSlotsPanel({
    super.key,
    required this.board,
    required this.onAddToCalendar,
    required this.highlight,
    this.link,
    this.fill = false,
  });

  final MeetingBoard board;
  final ValueChanged<MeetingRun>? onAddToCalendar;
  final MeetingRunHighlight highlight;
  final Uri? link;
  final bool fill;

  @override
  State<MeetingSlotsPanel> createState() => _MeetingSlotsPanelState();
}

class _MeetingSlotsPanelState extends State<MeetingSlotsPanel> {
  var _order = MeetingRunOrder.recommended;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// '모두 복사': 모임 제목과 링크, 그 아래 [runs]의 카드 글을 번호와 함께 빈 줄로 나눈다
  void _copyAll(List<MeetingRun> runs) {
    final board = widget.board;
    final text = [
      [
        board.meeting.title,
        if (widget.link case final link?) '$link',
      ].join('\n'),
      for (final (i, run) in runs.indexed) '${i + 1}. ${_copyText(board, run)}',
    ].join('\n\n');
    copyMeetingText(context, text, notice: '추천 시간을 모두 복사했습니다');
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    final scheme = Theme.of(context).colorScheme;
    final runs = board.runs(_order);
    final pinned = widget.highlight.pinned;
    if (pinned != null && !runs.any((run) => meetingRunKey(run) == pinned)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.highlight.unpin(),
      );
    }
    final Widget list = runs.isEmpty
        ? Text(
            '두 명 이상 함께 되는 시간이 생기면 여기에 추천해 드려요',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          )
        : ListenableBuilder(
            listenable: widget.highlight,
            builder: (context, _) => _RunList(
              board: board,
              runs: runs,
              highlight: widget.highlight,
              onAddToCalendar: widget.onAddToCalendar,
            ),
          );
    final panel = MeetingPanel(
      title: '추천 시간',
      help:
          '여러 사람이 함께 되는 시간을 보여 줘요. '
          '모모밋 추천은 사람이 많이 모이면서 오래 되는 시간을 먼저 보여 줘요',
      color: scheme.primaryContainer,
      foreground: scheme.onPrimaryContainer,
      fill: widget.fill,
      // 좁고 큰 글자면 정렬을 복사 아래로 내린다
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (runs.isNotEmpty)
            IconButton(
              tooltip: '모두 복사',
              visualDensity: VisualDensity.compact,
              color: scheme.onPrimaryContainer,
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: () => _copyAll(runs),
            ),
          _OrderMenu(
            mode: board.grid.mode,
            value: _order,
            onChanged: (order) => setState(() => _order = order),
          ),
        ],
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
    return ListenableBuilder(
      listenable: widget.highlight,
      builder: (context, child) =>
          IgnorePointer(ignoring: widget.highlight.painting, child: child),
      child: panel,
    );
  }
}

/// 카드 목록. 카드가 [_minCardWidth]보다 좁아지지 않게 한 줄의 카드 수를 정한다
class _RunList extends StatelessWidget {
  const _RunList({
    required this.board,
    required this.runs,
    required this.highlight,
    required this.onAddToCalendar,
  });

  final MeetingBoard board;
  final List<MeetingRun> runs;
  final MeetingRunHighlight highlight;
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
                  highlight: highlight,
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

/// [run]의 되는 사람과 안 되는 사람의 이름. 참여자 순서(주인이 앞)이고, 참여하기 전의 나는 맨 뒤다
({List<MeetingSlotPerson> people, List<String> unavailable}) _namesOf(
  MeetingBoard board,
  MeetingRun run,
) => (
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
      if (run.unavailable.contains(participant.id)) participant.displayName,
    if (run.unavailable.contains(MeetingBoard.pendingSelfId)) board.selfName,
  ],
);

/// [run] 카드를 복사할 글
String _copyText(MeetingBoard board, MeetingRun run) {
  final names = _namesOf(board, run);
  return meetingRunCopyText(
    board.grid,
    run,
    people: [for (final person in names.people) person.name],
    unavailable: names.unavailable,
  );
}

/// 묶음 하나의 카드
class _RunCard extends StatelessWidget {
  const _RunCard({
    super.key,
    required this.board,
    required this.run,
    required this.highlight,
    required this.onAddToCalendar,
  });

  final MeetingBoard board;
  final MeetingRun run;
  final MeetingRunHighlight highlight;
  final VoidCallback? onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final text = meetingRunText(board.grid, run);
    final names = _namesOf(board, run);
    final key = meetingRunKey(run);
    return MeetingSlotCard(
      pinned: highlight.pinned == key,
      onTap: () => highlight.toggle(key),
      onHoverChanged: (inside) => highlight.hover(
        inside ? key : (highlight.hovered == key ? null : highlight.hovered),
      ),
      title: text.title,
      detail: text.detail,
      people: names.people,
      unavailable: names.unavailable,
      onAddToCalendar: onAddToCalendar,
      onCopy: () => copyMeetingText(
        context,
        _copyText(board, run),
        notice: '추천 시간을 복사했습니다',
      ),
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
    MeetingRunOrder.recommended,
    MeetingRunOrder.people,
    MeetingRunOrder.date,
    MeetingRunOrder.length,
  ];

  String _label(MeetingRunOrder order) => switch (order) {
    MeetingRunOrder.recommended => '모모밋 추천',
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
        padding: const EdgeInsetsDirectional.only(start: 8),
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
