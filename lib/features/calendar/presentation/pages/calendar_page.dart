import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart' show ShellScope;
import 'package:momeet/shared/widgets/shell_tab_list.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/utils/calendar_date_utils.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_settings_drawer.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_selector.dart';

import '../widgets/schedule_form_sheet.dart';

/// 캘린더 메인 페이지
///
/// 캘린더 뷰와 네비게이션 컨트롤을 포함합니다.
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('달력'),
        centerTitle: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: ShellScope.compactOf(context) ? '화면 이동과 보기 설정' : '보기 설정',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: '필터',
            onPressed: () => _showFilterSheet(context),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: _CalendarToolbar(),
        ),
      ),
      drawer: CalendarSettingsDrawer(
        header: switch (ShellScope.maybeOf(context)) {
          final scope? when scope.compact => ShellTabList(
            current: scope.current,
            onSelect: scope.onSelect,
          ),
          _ => null,
        },
      ),
      body: const CalendarViewWidget(
        // TODO: 라우팅 연결
        // onScheduleTap: (id) => context.go('/schedule/detail?id=$id'),
        // onDateLongPress: (date) => _showCreateScheduleDialog(context, date),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showScheduleFormSheet(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 필터 시트 표시
  void _showFilterSheet(BuildContext context) {
    showAppScrollableSheet<void>(
      context,
      initialSize: 0.5,
      maxSize: 0.75,
      builder: (context, scrollController) =>
          _FilterSheetContent(scrollController: scrollController),
    );
  }
}

/// 필터 시트 내용
class _FilterSheetContent extends ConsumerWidget {
  const _FilterSheetContent({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(calendarFilterProvider);

    return Column(
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('필터', style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: () {
                  ref.read(calendarFilterProvider.notifier).clearFilters();
                },
                child: const Text('초기화'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 필터 옵션 목록
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // 취소된 일정 표시
              SwitchListTile(
                title: const Text('취소된 일정 표시'),
                value: filter.showCancelled,
                onChanged: (value) {
                  ref
                      .read(calendarFilterProvider.notifier)
                      .toggleShowCancelled();
                },
              ),
              const Divider(),
              // 태그 필터 섹션
              ListTile(
                title: const Text('태그 필터'),
                subtitle: Text(
                  filter.tagIds.isEmpty
                      ? '전체 표시'
                      : '${filter.tagIds.length}개 선택됨',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: 태그 선택 화면으로 이동
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 지금 보는 기간의 이름. [compact]면 좁은 화면에 맞게 줄여 쓴다
/// (주: '11월 8일 – 14일' / '11.8 – 14', 일: '2026년 11월 9일 (월)' / '11월 9일 (월)')
String periodLabel(CalendarSettingsState settings, {bool compact = false}) {
  final start = settings.displayDate;
  switch (settings.viewType) {
    case CalendarViewType.day:
      return DateFormat(
        compact ? 'M월 d일 (E)' : 'yyyy년 M월 d일 (E)',
        'ko',
      ).format(start);
    case CalendarViewType.week:
      final end = start.add(const Duration(days: DateTime.daysPerWeek - 1));
      final sameMonth = end.month == start.month;
      final (from, to) = compact
          ? ('M.d', sameMonth ? 'd' : 'M.d')
          : ('M월 d일', sameMonth ? 'd일' : 'M월 d일');
      return '${DateFormat(from, 'ko').format(start)} – '
          '${DateFormat(to, 'ko').format(end)}';
    case CalendarViewType.month:
    case CalendarViewType.agenda:
      return DateFormat('yyyy년 M월', 'ko').format(start);
    case CalendarViewType.year:
      return DateFormat('yyyy년', 'ko').format(start);
  }
}

/// 달력 도구 줄. 왼쪽은 기간 옮기기(오늘·이전·보는 기간·다음), 오른쪽은 보기 고르기.
/// 보는 기간을 누르면 날짜를 골라 그날로 간다
class _CalendarToolbar extends ConsumerWidget {
  const _CalendarToolbar();

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(calendarSettingsProvider);
    final picked = await showAppDatePicker(
      context,
      initial: settings.selectedDate,
      first: DateTime(2000),
      last: DateTime(2100),
    );
    if (picked != null) {
      ref.read(calendarSettingsProvider.notifier).goToDate(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(calendarSettingsProvider);
    final notifier = ref.read(calendarSettingsProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: '이전',
            visualDensity: VisualDensity.compact,
            onPressed: notifier.goToPrevious,
          ),
          const _TodayButton(),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: '다음',
            visualDensity: VisualDensity.compact,
            onPressed: notifier.goToNext,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _pickDate(context, ref),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_drop_down),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                label: Text(
                  periodLabel(
                    settings,
                    compact: MediaQuery.sizeOf(context).width < 600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const CalendarViewSelector(),
        ],
      ),
    );
  }
}

/// 오늘을 고르고 그 기간으로 가는 버튼. 지금 보는 기간에 오늘이 없으면 채워 눈에 띄게
/// 그리고 '오늘로 가기'로 읽힌다
class _TodayButton extends ConsumerWidget {
  const _TodayButton();

  static final _style = ButtonStyle(
    visualDensity: VisualDensity.compact,
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 12),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(calendarSettingsProvider);
    final todayInView = periodContains(
      settings.viewType,
      settings.displayDate,
      DateTime.now(),
      settings.firstDayOfWeek,
    );
    final goToToday = ref.read(calendarSettingsProvider.notifier).goToToday;
    const label = Text('오늘', semanticsLabel: '오늘');
    return todayInView
        ? OutlinedButton(onPressed: goToToday, style: _style, child: label)
        : FilledButton.tonal(
            onPressed: goToToday,
            style: _style,
            child: const Text('오늘', semanticsLabel: '오늘로 가기'),
          );
  }
}
