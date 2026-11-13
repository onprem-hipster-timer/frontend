import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/visibility/domain/resource_visibility.dart';
import 'package:momeet/features/visibility/domain/visibility_choice.dart';
import 'package:momeet/features/visibility/presentation/widgets/allow_list_editor.dart';
import 'package:momeet/features/visibility/presentation/widgets/friend_checklist.dart';
import 'package:momeet/features/visibility/presentation/widgets/visibility_audience.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/providers/friend_providers.dart';

/// 공유 범위 선택지의 이름과 설명
const _options = {
  VisibilityLevel.private: (label: '비공개', description: '나만 봄'),
  VisibilityLevel.friends: (label: '친구 공개', description: '모든 친구'),
  VisibilityLevel.selected: (label: '선택한 친구', description: '고른 친구만'),
  VisibilityLevel.allowedEmails: (
    label: '이메일·도메인 허용',
    description: '친구가 아니어도 적은 이메일·도메인의 사용자',
  ),
};

/// [target]의 공유 범위를 고르는 바텀 시트를 연다. 선택지는 [levels]를 이 순서로 보인다
///
/// 지금 설정을 읽어 고른 상태로 보여 주고, 저장하기 전에 누가 볼 수 있는지 알린다.
/// 저장하면 비공개는 설정을 지우고(DELETE), 그 외는 그 범위가 쓰는 목록만 보낸다(PUT).
/// 저장하면 시트를 닫고 알린 뒤 [onSaved]로 화면에 반영한다. 저장하는 사이 시트가 닫혀도 그렇게 한다.
/// 저장에 실패하면 알리고 고른 값을 둔 채 머문다.
///
/// 테스트: test/features/visibility/presentation/widgets/visibility_sheet_test.dart,
/// test/features/timer/presentation/widgets/timer_share_sheet_test.dart
Future<void> showVisibilitySheet(
  BuildContext context, {
  required ResourceVisibility target,
  required List<VisibilityLevel> levels,
  required Future<void> Function(ProviderContainer container) onSaved,
}) {
  return showAppSheet<void>(
    context,
    builder: (_) =>
        _VisibilitySheet(target: target, levels: levels, onSaved: onSaved),
  );
}

class _VisibilitySheet extends ConsumerStatefulWidget {
  const _VisibilitySheet({
    required this.target,
    required this.levels,
    required this.onSaved,
  });

  final ResourceVisibility target;
  final List<VisibilityLevel> levels;
  final Future<void> Function(ProviderContainer container) onSaved;

  @override
  ConsumerState<_VisibilitySheet> createState() => _VisibilitySheetState();
}

class _VisibilitySheetState extends ConsumerState<_VisibilitySheet> {
  /// 지금 설정을 읽는 중
  bool _loading = true;

  /// 지금 설정을 읽지 못한 오류
  Object? _loadError;

  bool _saving = false;

  var _choice = VisibilityChoice.from(null);

  /// 아직 허용 목록에 넣지 않은 이메일·도메인 입력
  final _draft = TextEditingController();

  /// [_draft]를 넣지 못한 까닭
  String? _draftError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final visibility = await widget.target.load();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _choice = VisibilityChoice.from(visibility);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error;
      });
    }
  }

  void _retry() {
    // 다시 그리기 전에 연달아 누른 다시 시도는 읽지 않는다
    if (_loadError == null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  /// [_draft]를 허용 목록에 넣고 넣지 못한 것만 칸에 남긴다. 형식이 틀린 것이 없으면 true
  bool _addDraft() {
    final rejects = _choice.allowList.add(_draft.text);
    setState(() {
      _draft.text = rejects.invalid.join(', ');
      _draftError = rejects.invalid.isNotEmpty
          ? '이메일이나 도메인 형식이 아닙니다: ${rejects.invalid.join(', ')}'
          : rejects.duplicate.isNotEmpty
          ? '이미 넣었습니다: ${rejects.duplicate.join(', ')}'
          : null;
    });
    return rejects.invalid.isEmpty;
  }

  void _clearDraftError() {
    if (_draftError != null) setState(() => _draftError = null);
  }

  Future<void> _save(List<FriendRead>? friends) async {
    // 다시 그리기 전에 연달아 누른 저장은 보내지 않는다
    if (_saving) return;
    // 칸에 남은 입력도 넣는다. 틀린 입력이 있으면 저장하지 않는다
    if (_choice.level == VisibilityLevel.allowedEmails &&
        _draft.text.trim().isNotEmpty &&
        !_addDraft()) {
      return;
    }
    final update = _choice.update(friends);
    final target = widget.target;
    final onSaved = widget.onSaved;
    // 저장하는 사이 시트가 닫혀도 결과를 알리고 반영한다
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _saving = true);
    try {
      if (update == null) {
        await target.clear();
      } else {
        await target.save(update);
      }
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      messenger.showAppSnackBar('${Terms.visibility} 저장 실패: $error');
      return;
    }
    // 저장하는 사이 시트를 닫았으면 그 아래 화면은 닫지 않는다
    if (mounted && (ModalRoute.isCurrentOf(context) ?? false)) {
      Navigator.of(context).pop();
    }
    messenger.showAppSnackBar('${Terms.visibility.withJosa('을', '를')} 저장했습니다');
    await onSaved(container);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(32), child: AppLoading());
    }

    if (_loadError != null) {
      return AppErrorState(
        title: '${Terms.visibility.withJosa('을', '를')} 불러오지 못했습니다',
        onRetry: _retry,
      );
    }

    final level = _choice.level;
    // 친구 공개도 친구가 있는지 알아야 볼 수 있는 사람을 알린다
    final friends =
        level == VisibilityLevel.friends || level == VisibilityLevel.selected
        ? ref.watch(friendsProvider)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Terms.visibility,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _LevelChoices(
            levels: widget.levels,
            level: level,
            enabled: !_saving,
            onChanged: (level) => setState(() => _choice.level = level),
          ),
          if (level == VisibilityLevel.allowedEmails)
            AllowListEditor(
              emails: _choice.allowList.emails,
              domains: _choice.allowList.domains,
              draft: _draft,
              error: _draftError,
              enabled: !_saving,
              onSubmit: _addDraft,
              onDraftChanged: _clearDraftError,
              onRemove: (entry) =>
                  setState(() => _choice.allowList.remove(entry)),
            ),
          if (friends != null && level == VisibilityLevel.selected)
            FriendChecklist(
              friends: friends,
              selected: _choice.friendIds,
              enabled: !_saving,
              onChanged: (id, checked) => setState(
                () => checked
                    ? _choice.friendIds.add(id)
                    : _choice.friendIds.remove(id),
              ),
              onRetry: () => ref.invalidate(friendsProvider),
            ),
          const SizedBox(height: 16),
          VisibilityAudience(choice: _choice, friends: friends?.value),
          const SizedBox(height: 8),
          AppFormActionBar(
            submitLabel: '저장',
            onSubmit: _choice.canSave(friends?.value)
                ? () => _save(friends?.value)
                : null,
            busy: _saving,
          ),
        ],
      ),
    );
  }
}

/// 공유 범위 선택지 [levels]. 지금 고른 것은 [level]
class _LevelChoices extends StatelessWidget {
  const _LevelChoices({
    required this.levels,
    required this.level,
    required this.enabled,
    required this.onChanged,
  });

  final List<VisibilityLevel> levels;
  final VisibilityLevel level;
  final bool enabled;
  final ValueChanged<VisibilityLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<VisibilityLevel>(
      groupValue: level,
      onChanged: (level) {
        if (level != null) onChanged(level);
      },
      child: Column(
        children: [
          for (final level in levels)
            RadioListTile<VisibilityLevel>(
              value: level,
              enabled: enabled,
              title: Text(_options[level]!.label),
              subtitle: Text(_options[level]!.description),
            ),
        ],
      ),
    );
  }
}
