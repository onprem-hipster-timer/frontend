import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view.dart';

import '../widgets/schedule_form_sheet.dart';

/// 캘린더 메인 페이지
///
/// 캘린더 뷰와 네비게이션 컨트롤을 포함합니다.
class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(context, ref),
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

  /// AppBar 빌드
  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(calendarSettingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: _buildTitle(context, ref, settings),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          // TODO: 드로어 열기 또는 네비게이션
          Scaffold.of(context).openDrawer();
        },
      ),
      actions: [
        // 오늘 버튼
        IconButton(
          icon: const Icon(Icons.today),
          tooltip: '오늘',
          onPressed: () {
            ref.read(calendarSettingsProvider.notifier).goToToday();
          },
        ),
        // 뷰 모드 선택
        PopupMenuButton<CalendarViewType>(
          icon: const Icon(Icons.view_agenda),
          tooltip: '뷰 모드',
          initialValue: settings.viewType,
          onSelected: (viewType) {
            ref.read(calendarSettingsProvider.notifier).setViewType(viewType);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: CalendarViewType.day,
              child: Row(
                children: [
                  Icon(Icons.view_day, size: 20),
                  SizedBox(width: 12),
                  Text('일간'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: CalendarViewType.week,
              child: Row(
                children: [
                  Icon(Icons.view_week, size: 20),
                  SizedBox(width: 12),
                  Text('주간'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: CalendarViewType.month,
              child: Row(
                children: [
                  Icon(Icons.calendar_view_month, size: 20),
                  SizedBox(width: 12),
                  Text('월간'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: CalendarViewType.agenda,
              child: Row(
                children: [
                  Icon(Icons.view_list, size: 20),
                  SizedBox(width: 12),
                  Text('아젠다'),
                ],
              ),
            ),
          ],
        ),
        // 필터 버튼
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: '필터',
          onPressed: () {
            _showFilterSheet(context, ref);
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: _buildNavigationBar(context, ref, settings, colorScheme),
      ),
    );
  }

  /// 타이틀 빌드
  Widget _buildTitle(
    BuildContext context,
    WidgetRef ref,
    CalendarSettingsState settings,
  ) {
    final displayDate = settings.displayDate;
    String titleText;

    switch (settings.viewType) {
      case CalendarViewType.day:
        titleText = DateFormat('yyyy년 M월 d일 (E)', 'ko').format(displayDate);
        break;
      case CalendarViewType.week:
        final startOfWeek =
            displayDate.subtract(Duration(days: displayDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        titleText =
            '${DateFormat('M/d', 'ko').format(startOfWeek)} - ${DateFormat('M/d', 'ko').format(endOfWeek)}';
        break;
      case CalendarViewType.month:
      case CalendarViewType.year:
      case CalendarViewType.agenda:
        titleText = DateFormat('yyyy년 M월', 'ko').format(displayDate);
        break;
    }

    return GestureDetector(
      onTap: () => _showDatePicker(context, ref),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(titleText),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
    );
  }

  /// 네비게이션 바 빌드
  Widget _buildNavigationBar(
    BuildContext context,
    WidgetRef ref,
    CalendarSettingsState settings,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 이전 버튼
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(calendarSettingsProvider.notifier).goToPrevious();
            },
          ),
          // 선택된 날짜 표시
          Text(
            DateFormat('M월 d일 (E)', 'ko').format(settings.selectedDate),
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          // 다음 버튼
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(calendarSettingsProvider.notifier).goToNext();
            },
          ),
        ],
      ),
    );
  }

  /// 날짜 선택기 표시
  Future<void> _showDatePicker(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(calendarSettingsProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: settings.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null) {
      ref.read(calendarSettingsProvider.notifier).setSelectedDate(picked);
      ref.read(calendarSettingsProvider.notifier).setDisplayDate(picked);
    }
  }

  /// 필터 시트 표시
  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.75,
        expand: false,
        builder: (context, scrollController) {
          return _FilterSheetContent(scrollController: scrollController);
        },
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 핸들
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.outline.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // 헤더
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '필터',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
                  ref.read(calendarFilterProvider.notifier).toggleShowCancelled();
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
