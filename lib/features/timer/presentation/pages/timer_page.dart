import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart'
    show ShellMenuButton, ShellScope;
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:momeet/shared/widgets/error_banner.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_history_list.dart';

/// 타이머 대시보드 페이지
///
/// 실시간 타이머 표시, 제어 버튼, 히스토리 목록을 제공합니다.
/// 넓은 화면은 다이얼 옆에 타이머 목록을 두고, 좁은 화면은 다이얼만 두고 앱 바에서 목록을 엽니다.
class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  /// 레이아웃이 바뀌어도 대시보드 상태(다이얼로 고른 시간)를 옮겨 쓴다
  final _dashboardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final focus = ShellScope.compactOf(context);
    final dashboard = TimerDashboard(
      key: _dashboardKey,
      focusLeading: const ShellMenuButton(),
      focusActions: [
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: '타이머 목록',
          onPressed: () => _showHistorySheet(context),
        ),
      ],
    );

    final lastError = ref.watch(timerWsLastErrorProvider);

    ref.listen<AsyncValue<TimerWsTimerEvent>>(timerFriendActivityProvider, (
      _,
      next,
    ) {
      next.whenData((event) {
        // 시간 종료(expire)는 함께 오는 명령(정지 등)의 알림과 겹치므로 띄우지 않는다
        if (event.payload.action == 'expire' || !context.mounted) return;
        showAppSnackBar(context, friendActivityMessage(event));
      });
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= timerWideLayoutMinWidth;

        // 집중 보기는 앱바 없이 대시보드의 작업명 줄이 ☰와 목록 버튼을 맡는다
        return Scaffold(
          appBar: focus
              ? null
              : AppBar(
                  title: const Text('타이머'),
                  elevation: 0,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  actions: [
                    if (!wide)
                      IconButton(
                        icon: const Icon(Icons.history),
                        tooltip: '타이머 목록',
                        onPressed: () => _showHistorySheet(context),
                      ),
                  ],
                ),
          body: SafeArea(
            // 집중 보기는 앱바가 없어 상태 표시줄 아래부터 그린다
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: ErrorBanner(
                    message: lastError?.message,
                    onDismiss: () => ref
                        .read(timerWsLastErrorProvider.notifier)
                        .setError(null),
                  ),
                ),
                Expanded(
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 3, child: dashboard),
                            const VerticalDivider(width: 1),
                            const Expanded(flex: 2, child: TimerHistoryList()),
                          ],
                        )
                      : dashboard,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHistorySheet(BuildContext context) {
    showAppScrollableSheet<void>(
      context,
      builder: (_, scrollController) =>
          TimerHistoryList(scrollController: scrollController),
    );
  }
}

/// 친구의 타이머 이벤트를 SnackBar 문구로 변환한다.
///
/// `payload.action` 중 start/pause/resume/stop만 매핑하고,
/// 그 외 action은 generic fallback 문구로 처리한다.
/// `payload.actor_name`이 없거나 빈 문자열이면 `친구`로 대체한다.
String friendActivityMessage(TimerWsTimerEvent event) {
  final actorName = event.payload.actorName?.trim();
  final friendName = actorName == null || actorName.isEmpty ? '친구' : actorName;
  final timerTitle = event.payload.timer?.title?.trim();
  final target = timerTitle == null || timerTitle.isEmpty
      ? '타이머'
      : '$timerTitle 타이머';

  return switch (event.payload.action) {
    'start' => '$friendName님이 $target를 시작했습니다',
    'pause' => '$friendName님이 $target를 일시정지했습니다',
    'resume' => '$friendName님이 $target를 재개했습니다',
    'stop' => '$friendName님이 $target를 정지했습니다',
    _ => '$friendName님의 타이머 상태가 변경되었습니다',
  };
}
