import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_link.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_date_badge.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_glass_scaffold.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_row.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_qr_code.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임을 만든 뒤 화면(탭 셸 밖). 링크를 복사하거나 내 시간을 넣으러 모임 화면(주소도 그 모임 링크)으로 간다.
///
/// 두 단추 아래의 '또는 QR로 공유하기'를 누르면 첫날 달력 그림이 그 자리에서 뒤집혀 모임 링크 QR 코드와 링크가
/// 되고, 'QR 가리기'로 되돌린다(애니메이션을 줄였으면 움직임 없이 바꾼다).
class MeetingCreatedPage extends ConsumerStatefulWidget {
  const MeetingCreatedPage({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<MeetingCreatedPage> createState() => _MeetingCreatedPageState();
}

class _MeetingCreatedPageState extends ConsumerState<MeetingCreatedPage> {
  var _qr = false;

  @override
  Widget build(BuildContext context) {
    final meetingId = widget.meetingId;
    final meeting = ref.watch(meetingProvider(meetingId)).value;
    final theme = Theme.of(context);
    return MeetingGlassScaffold(
      title: const Text('새 ${Terms.meeting}'),
      // 본문 안의 MediaQuery가 머리띠 높이를 담는다
      body: Builder(
        builder: (context) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(
              24,
            ).add(EdgeInsets.only(top: MediaQuery.paddingOf(context).top)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${Terms.meeting} 생성이 완료되었어요 :)',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _Illustration(
                    qr: _qr,
                    calendar: MeetingDateBadge(day: meeting?.startDate),
                    link: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MeetingQrCode(
                          data: '${meetingLink(context, ref, meetingId)}',
                        ),
                        const SizedBox(height: 12),
                        MeetingLinkRow(meetingId: meetingId),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.tonal(
                    onPressed: () => copyMeetingLink(context, ref, meetingId),
                    child: const Text('링크 공유'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.goNamed(
                      AppRoute.meeting.name,
                      pathParameters: {'meetingId': meetingId},
                    ),
                    child: const Text('나의 일정 입력'),
                  ),
                  const SizedBox(height: 16),
                  _QrToggle(
                    showing: _qr,
                    onPressed: () => setState(() => _qr = !_qr),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 달력 그림 자리. [qr]이면 같은 자리에서 뒤집혀 [link](QR과 링크)가 되고, 크기는 부드럽게 바뀐다
class _Illustration extends StatelessWidget {
  const _Illustration({
    required this.qr,
    required this.calendar,
    required this.link,
  });

  final bool qr;
  final Widget calendar;
  final Widget link;

  static const _duration = Duration(milliseconds: 360);

  @override
  Widget build(BuildContext context) {
    final shown = qr
        ? KeyedSubtree(key: const ValueKey('qr'), child: link)
        : Center(key: const ValueKey('calendar'), child: calendar);
    // 애니메이션을 줄였으면 움직임 없이 바꾼다
    if (MediaQuery.disableAnimationsOf(context)) return shown;
    return AnimatedSize(
      duration: _duration,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: _duration,
        transitionBuilder: (child, animation) =>
            _Flip(animation: animation, child: child),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: shown,
      ),
    );
  }
}

/// 앞 그림은 처음 절반 동안 옆으로 돌아 사라지고, 새 그림은 나머지 절반 동안 돌아 들어온다
class _Flip extends StatelessWidget {
  const _Flip({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final turn = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.5, 1, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: turn,
      child: child,
      builder: (context, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY((1 - turn.value) * math.pi / 2),
        child: child,
      ),
    );
  }
}

/// '또는 QR로 공유하기'(QR을 보이면 'QR 가리기'). 양옆에 선을 둔 단추다
class _QrToggle extends StatelessWidget {
  const _QrToggle({required this.showing, required this.onPressed});

  final bool showing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.mdAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                const Expanded(child: Divider()),
                // 글은 폭의 60%까지 쓰고 넘으면 줄을 바꾼다. 남는 폭은 양옆 선이 똑같이 나눈다
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.6,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      showing ? 'QR 가리기' : '또는 QR로 공유하기',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
