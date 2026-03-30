// Timezone Selection Bottom Sheet
//
// 사용자가 타임존을 선택할 수 있는 모달 바텀 시트
// IANA 타임존 DB에서 전체 목록을 표시하며 검색 필터를 제공합니다.

import 'package:flutter/material.dart';
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
    final currentTimezone = ref.watch(timezoneProvider);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들 바
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Padding(
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
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                final displayName = getTimezoneDisplayName(timezone);
                final isSelected = timezone == currentTimezone;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  title: Text(
                    displayName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
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
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          color: theme.colorScheme.primary,
                          size: 24,
                        )
                      : null,
                  onTap: () async {
                    await ref
                        .read(timezoneProvider.notifier)
                        .updateTimezone(timezone);

                    if (context.mounted) {
                      context.pop();
                    }
                  },
                );
              },
            ),
          ),

          // 하단 여백 (안전 영역)
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// 타임존 선택 시트를 표시하는 헬퍼 함수
///
/// useRootNavigator: true 옵션을 사용하여 네비게이션 바 딤 이슈를 방지합니다.
Future<void> showTimezoneSelectionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true, // 중요: 네비게이션 바 딤 이슈 방지
    builder: (context) => const TimezoneSelectionSheet(),
  );
}
