import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_run_copy.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_chip.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 카드에 보이는 참여자 한 명
typedef MeetingSlotPerson = ({String name, bool owner, bool guest, bool self});

/// 추천 시간 카드: 날짜, 시각(날 수), 되는 사람 수, '복사'([onCopy])와 '내 달력에 넣기'([onAddToCalendar]가
/// 있을 때). 카드의 글은 마우스로 끌거나 길게 눌러 골라 복사할 수 있다(누르면 펼치는 것은 그대로다).
///
/// 이름은 고정하기 전에는 마우스를 올리면 카드 아래에 떠서 보이고([onHoverChanged]도 부른다), 카드를 누르면
/// ([onTap]) 고정되어([pinned]) 카드 안에 남는다. 고정은 카드 밖(목록)이 한 번에 하나로 정한다. 그 시간이 안
/// 되는 사람([unavailable])은 이름 아래 한 줄로만 덧붙인다.
class MeetingSlotCard extends StatefulWidget {
  const MeetingSlotCard({
    super.key,
    required this.title,
    required this.detail,
    required this.people,
    required this.onAddToCalendar,
    required this.onCopy,
    required this.pinned,
    required this.onTap,
    this.onHoverChanged,
    this.unavailable = const [],
  });

  final bool pinned;
  final VoidCallback onTap;
  final ValueChanged<bool>? onHoverChanged;

  final String title;
  final String detail;
  final List<MeetingSlotPerson> people;

  /// 그 시간의 칸 중 하나라도 안 된다고 한 사람의 이름
  final List<String> unavailable;
  final VoidCallback? onAddToCalendar;
  final VoidCallback onCopy;

  @override
  State<MeetingSlotCard> createState() => _MeetingSlotCardState();
}

class _MeetingSlotCardState extends State<MeetingSlotCard> {
  final _link = LayerLink();
  final _hover = OverlayPortalController();

  void _toggle() {
    _hover.hide();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => OverlayPortal(
        controller: _hover,
        overlayChildBuilder: (context) => _HoverNames(
          link: _link,
          width: constraints.maxWidth,
          people: widget.people,
          unavailable: widget.unavailable,
        ),
        child: CompositedTransformTarget(
          link: _link,
          child: MouseRegion(
            onEnter: (_) {
              if (!widget.pinned) _hover.show();
              widget.onHoverChanged?.call(true);
            },
            onExit: (_) {
              _hover.hide();
              widget.onHoverChanged?.call(false);
            },
            child: SelectionArea(
              child: _CardFace(
                title: widget.title,
                detail: widget.detail,
                people: widget.people,
                unavailable: widget.unavailable,
                pinned: widget.pinned,
                width: constraints.maxWidth,
                onTap: _toggle,
                onAddToCalendar: widget.onAddToCalendar,
                onCopy: widget.onCopy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 카드 겉: 위 줄에 날짜, 사람 수, 펼침 표시, 그 아래 시각, 고정하면 이름, 맨 아래 줄에 '내 달력에 넣기'(있을 때)와
/// 끝의 복사. 카드가 좁아 '내 달력에 넣기'와 복사가 한 줄에 안 들어가면 '내 달력에 넣기'가 아래 줄을 다 쓰고 복사는
/// 위 줄의 사람 수 앞으로 간다
class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.title,
    required this.detail,
    required this.people,
    required this.unavailable,
    required this.pinned,
    required this.width,
    required this.onTap,
    required this.onAddToCalendar,
    required this.onCopy,
  });

  final String title;
  final String detail;
  final List<MeetingSlotPerson> people;
  final List<String> unavailable;
  final bool pinned;
  final double width;
  final VoidCallback onTap;
  final VoidCallback? onAddToCalendar;
  final VoidCallback onCopy;

  static const _padding = EdgeInsets.fromLTRB(14, 12, 6, 6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final onAddToCalendar = this.onAddToCalendar;
    final shared =
        onAddToCalendar == null ||
        _CalendarButton.widthIn(context) + _copySize <=
            width - _padding.horizontal;
    final copy = IconButton(
      tooltip: '복사',
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      color: muted,
      icon: const Icon(Icons.content_copy_outlined),
      onPressed: onCopy,
    );
    return Material(
      color: scheme.surface,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Semantics(
          expanded: pinned,
          selected: pinned,
          child: Padding(
            padding: _padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!shared) copy,
                    const SizedBox(width: 8),
                    _HeadCount(people.length),
                    const SizedBox(width: 2),
                    ExcludeSemantics(
                      child: Icon(
                        pinned ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: muted,
                      ),
                    ),
                    // 펼침 표시의 끝을 아래 줄 복사 아이콘의 끝에 맞춘다
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 2),
                Text(detail, style: theme.textTheme.bodyMedium),
                if (pinned)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _Names(people: people, unavailable: unavailable),
                  ),
                const SizedBox(height: 8),
                _ActionRow(
                  onAddToCalendar: onAddToCalendar,
                  copy: shared ? copy : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 촘촘한 복사 단추의 너비
  static const _copySize = 40.0;
}

/// 맨 아래 줄: 앞에 '내 달력에 넣기'(있을 때), 끝에 [copy](위 줄로 옮기지 않았을 때). [copy]가 없으면
/// '내 달력에 넣기'가 줄을 다 쓴다
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onAddToCalendar, required this.copy});

  final VoidCallback? onAddToCalendar;
  final Widget? copy;

  @override
  Widget build(BuildContext context) {
    final onAddToCalendar = this.onAddToCalendar;
    final copy = this.copy;
    return switch ((onAddToCalendar, copy)) {
      (null, final copy?) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: copy,
      ),
      (final onPressed?, final copy?) => Row(
        children: [
          _CalendarButton(onPressed: onPressed),
          const Spacer(),
          copy,
        ],
      ),
      (final onPressed?, null) => _CalendarButton(onPressed: onPressed),
      (null, null) => const SizedBox.shrink(),
    };
  }
}

/// 사람 아이콘과 인원수
class _HeadCount extends StatelessWidget {
  const _HeadCount(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Semantics(
      label: '$count명',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 마우스를 올렸을 때 카드 아래에 뜨는 이름
class _HoverNames extends StatelessWidget {
  const _HoverNames({
    required this.link,
    required this.width,
    required this.people,
    required this.unavailable,
  });

  final LayerLink link;
  final double width;
  final List<MeetingSlotPerson> people;
  final List<String> unavailable;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformFollower(
      link: link,
      targetAnchor: Alignment.bottomLeft,
      offset: const Offset(0, 4),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: IgnorePointer(
            child: Material(
              elevation: 4,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: AppRadius.lgAll,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _Names(people: people, unavailable: unavailable),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 되는 사람 칩과, 있으면 그 아래 안 되는 사람 한 줄('불가능 1명 · 다현')
class _Names extends StatelessWidget {
  const _Names({required this.people, required this.unavailable});

  final List<MeetingSlotPerson> people;
  final List<String> unavailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 떠 있는 이름 상자는 화면 높이를 받으므로 내용 높이에 맞춘다
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final person in people)
              MeetingNameChip(
                name: person.name,
                owner: person.owner,
                guest: person.guest,
                self: person.self,
                dense: true,
              ),
          ],
        ),
        if (unavailable.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              meetingUnavailableLine(unavailable),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// '내 달력에 넣기': 그 시간과 모임 제목으로 새 일정을 연다
class _CalendarButton extends StatelessWidget {
  const _CalendarButton({required this.onPressed});

  final VoidCallback onPressed;

  static const _label = '내 달력에 넣기';
  static const _iconSize = 18.0;
  static const _gap = 8.0;
  static const _padding = 12.0;

  /// 글자 크기를 반영한 이 단추의 너비
  static double widthIn(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: _label,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return _padding * 2 + _iconSize + _gap + width;
  }

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: _padding),
    ),
    icon: const Icon(Icons.edit_calendar_outlined, size: _iconSize),
    label: const Text(_label),
  );
}
