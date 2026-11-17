import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_chip.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 카드에 보이는 참여자 한 명
typedef MeetingSlotPerson = ({String name, bool owner, bool guest, bool self});

/// 추천 시간 카드: 날짜, 시각(날 수), 되는 사람 수와 '내 달력에 일정 만들기'([onAddToCalendar]가 있을 때).
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

  @override
  State<MeetingSlotCard> createState() => _MeetingSlotCardState();
}

class _MeetingSlotCardState extends State<MeetingSlotCard> {
  /// 이 너비부터 시각 줄에 펼침 표시와 달력 버튼을 함께 둔다
  static const _wideFrom = 260.0;

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
            child: _CardFace(
              title: widget.title,
              detail: widget.detail,
              people: widget.people,
              unavailable: widget.unavailable,
              pinned: widget.pinned,
              wide: constraints.maxWidth >= _wideFrom,
              onTap: _toggle,
              onAddToCalendar: widget.onAddToCalendar,
            ),
          ),
        ),
      ),
    );
  }
}

/// 카드 겉: 날짜·사람 수, 시각, 고정하면 이름, 펼침 표시·달력 버튼. 넓으면 버튼을 시각 줄에 둔다
class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.title,
    required this.detail,
    required this.people,
    required this.unavailable,
    required this.pinned,
    required this.wide,
    required this.onTap,
    required this.onAddToCalendar,
  });

  final String title;
  final String detail;
  final List<MeetingSlotPerson> people;
  final List<String> unavailable;
  final bool pinned;
  final bool wide;
  final VoidCallback onTap;
  final VoidCallback? onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final actions = _Actions(
      pinned: pinned,
      wide: wide,
      onAddToCalendar: onAddToCalendar,
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
            padding: EdgeInsets.fromLTRB(14, wide ? 8 : 12, 8, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _HeadCount(people.length),
                  ],
                ),
                const SizedBox(height: 2),
                if (wide)
                  Row(
                    children: [
                      Expanded(
                        child: Text(detail, style: theme.textTheme.bodyMedium),
                      ),
                      actions,
                    ],
                  )
                else
                  Text(detail, style: theme.textTheme.bodyMedium),
                if (pinned)
                  Padding(
                    padding: EdgeInsets.only(top: 8, bottom: wide ? 10 : 0),
                    child: _Names(people: people, unavailable: unavailable),
                  ),
                if (!wide) actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 펼침 표시와 '내 달력에 일정 만들기'. 좁으면 둘을 양 끝에 둔다. 달력 단추가 없으면 펼침 표시만 둔다
class _Actions extends StatelessWidget {
  const _Actions({
    required this.pinned,
    required this.wide,
    required this.onAddToCalendar,
  });

  final bool pinned;
  final bool wide;
  final VoidCallback? onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final onAddToCalendar = this.onAddToCalendar;
    return Row(
      mainAxisSize: wide ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          // 달력 단추가 없어도 카드 높이와 펼침 표시 자리가 같게 둔다
          padding: EdgeInsets.symmetric(
            vertical: onAddToCalendar == null ? 10 : 0,
          ),
          child: ExcludeSemantics(
            child: Icon(
              pinned ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (onAddToCalendar != null)
          IconButton(
            tooltip: '내 달력에 일정 만들기',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_calendar_outlined),
            onPressed: onAddToCalendar,
          ),
      ],
    );
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
    return Column(
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
              '불가능 ${unavailable.length}명 · ${unavailable.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
