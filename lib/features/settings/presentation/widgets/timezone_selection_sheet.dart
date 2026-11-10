// Timezone Selection Bottom Sheet
//
// 사용자가 타임존을 선택할 수 있는 모달 바텀 시트
// IANA 타임존 DB에서 전체 목록을 표시하며 검색 필터를 제공합니다.

import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/core/providers/timezone_provider.dart';

/// 타임존 선택 바텀 시트
class TimezoneSelectionSheet extends ConsumerStatefulWidget {
  const TimezoneSelectionSheet({super.key});

  @override
  ConsumerState<TimezoneSelectionSheet> createState() =>
      _TimezoneSelectionSheetState();
}

class _TimezoneSelectionSheetState
    extends ConsumerState<TimezoneSelectionSheet> {
  final _searchController = TextEditingController();
  late List<String> _allTimezones;
  List<String> _filteredTimezones = [];

  @override
  void initState() {
    super.initState();
    _allTimezones = getAllTimezones();
    _filteredTimezones = _allTimezones;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTimezones = _allTimezones;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredTimezones = _allTimezones
            .where((tz) => tz.toLowerCase().contains(lowerQuery))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTimezone =
        ref.watch(timezoneProvider).value ?? defaultTimezone;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: [
          const _SheetHeader(),

          // 검색 필드
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '도시 또는 타임존 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // 타임존 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredTimezones.length,
              itemBuilder: (context, index) {
                final timezone = _filteredTimezones[index];
                return _TimezoneTile(
                  timezone: timezone,
                  selected: timezone == currentTimezone,
                  onTap: () async {
                    await ref
                        .read(timezoneProvider.notifier)
                        .updateTimezone(timezone);
                    if (context.mounted) context.pop();
                  },
                );
              },
            ),
          ),

          // 하단 여백 (안전 영역)
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}

/// 시트 제목과 닫기 버튼
class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Text(
            '타임존 선택',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 타임존 한 줄. 고른 것은 강조하고 체크를 둔다
class _TimezoneTile extends StatelessWidget {
  const _TimezoneTile({
    required this.timezone,
    required this.selected,
    required this.onTap,
  });

  final String timezone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = getTimezoneDisplayName(timezone);
    return ListTile(
      selected: selected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(
        displayName,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        timezone,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check, color: theme.colorScheme.primary, size: 24)
          : null,
      onTap: onTap,
    );
  }
}

/// 타임존 선택 시트를 표시하는 헬퍼 함수
///
/// useRootNavigator: true 옵션을 사용하여 네비게이션 바 딤 이슈를 방지합니다.
Future<void> showTimezoneSelectionSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    builder: (context) => const TimezoneSelectionSheet(),
  );
}
