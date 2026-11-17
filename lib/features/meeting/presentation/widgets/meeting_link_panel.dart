import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_link.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_audience.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 수정하기를 누를 수 없을 때의 안내
const meetingEditOwnerOnly = '모임을 만든 사람만 수정할 수 있어요';

/// 모임을 보던 사람이 자기 모임을 만들러 가는 버튼
const meetingCreateOwn = '나도 모임 만들기';

/// 주인이 모임을 하나 더 만들러 가는 버튼
const meetingCreateAnother = '새 모임 만들기';

/// '링크': '공유하기'([shareMeetingLink])와 '수정하기'(주인만 모임 설정을 연다. 다른 사람에게는 막혀 있고 만든
/// 사람만 고칠 수 있다고 알린다)를 같은 폭으로 나란히 둔다(큰 글자로 넘치면 위아래로 쌓는다). 비공개 모임([level])이면
/// 그 아래에 누가 열 수 있는지 한 줄로 알린다. 제목 줄 끝의 '나도 모임 만들기'(주인에게는 '새 모임 만들기')는
/// 모임 만들기 화면을 연다
class MeetingLinkPanel extends ConsumerWidget {
  const MeetingLinkPanel({
    super.key,
    required this.meetingId,
    required this.title,
    this.owner = false,
    this.level,
  });

  final String meetingId;

  /// 공유 창에 넣는 모임 제목
  final String title;

  /// 로그인한 사람이 주인인지
  final bool owner;

  /// 모임의 공개 범위. 모르면 null(알리지 않는다)
  final VisibilityLevel? level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = this.level;
    return MeetingPanel(
      title: '링크',
      trailing: TextButton.icon(
        onPressed: () => openMeetingCreate(context),
        icon: const Icon(Icons.add, size: 18),
        label: Text(owner ? meetingCreateAnother : meetingCreateOwn),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LinkButtons(
            onShare: () => shareMeetingLink(
              context,
              ref,
              meetingId: meetingId,
              title: title,
            ),
            onEdit: owner ? () => openMeetingEdit(context, meetingId) : null,
          ),
          if (level != null && level != VisibilityLevel.public) ...[
            const SizedBox(height: 8),
            MeetingLinkAudience(level: level),
          ],
        ],
      ),
    );
  }
}

/// 공유하기와 수정하기. 한 줄에 들어가면 같은 폭으로 나란히, 아니면 위아래로 쌓는다
class _LinkButtons extends StatelessWidget {
  const _LinkButtons({required this.onShare, required this.onEdit});

  final VoidCallback onShare;

  /// null이면 누를 수 없다(주인이 아니다)
  final VoidCallback? onEdit;

  static const _gap = 8.0;
  static const _labels = ['공유하기', '수정하기'];

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    final buttonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
    );
    final share = FilledButton.icon(
      onPressed: onShare,
      style: buttonStyle,
      icon: const Icon(Icons.ios_share, size: 18),
      label: Text(_labels[0]),
    );
    final editButton = OutlinedButton.icon(
      onPressed: onEdit,
      style: buttonStyle,
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: Text(_labels[1]),
    );
    final edit = onEdit == null
        ? Tooltip(message: meetingEditOwnerOnly, child: editButton)
        : editButton;
    return LayoutBuilder(
      builder: (context, constraints) {
        final widest = _labels
            .map((label) {
              final painter = TextPainter(
                text: TextSpan(text: label, style: style),
                textDirection: TextDirection.ltr,
                textScaler: scaler,
              )..layout();
              final width = painter.width;
              painter.dispose();
              return width;
            })
            .reduce(math.max);
        // 아이콘과 안쪽 여백을 더한 폭이 반 줄에 들어가면 나란히 둔다
        final side = (widest + scaler.scale(18) + 56) * 2 + _gap;
        if (side <= constraints.maxWidth) {
          return Row(
            children: [
              Expanded(child: share),
              const SizedBox(width: _gap),
              Expanded(child: edit),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            share,
            const SizedBox(height: _gap),
            edit,
          ],
        );
      },
    );
  }
}
