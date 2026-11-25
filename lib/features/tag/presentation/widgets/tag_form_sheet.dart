import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/tag_providers.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_form_sheet_view.dart';

/// 태그 생성/수정 폼 시트
class TagFormSheet extends ConsumerStatefulWidget {
  final TagRead? tag;
  final String? defaultGroupId;

  const TagFormSheet({super.key, this.tag, this.defaultGroupId});

  @override
  ConsumerState<TagFormSheet> createState() => _TagFormSheetState();
}

class _TagFormSheetState extends ConsumerState<TagFormSheet> {
  late final bool _isEditMode = widget.tag != null;

  @override
  Widget build(BuildContext context) {
    final isLoading = _isEditMode
        ? ref.watch(updateTagMutation).isPending
        : ref.watch(createTagMutation).isPending;

    return TagFormSheetView(
      tag: widget.tag,
      defaultGroupId: widget.defaultGroupId,
      groups: ref.watch(tagTreeProvider),
      busy: isLoading,
      onSubmit: _handleSubmit,
    );
  }

  Future<void> _handleSubmit(String name, Color color, String groupId) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (_isEditMode) {
        final updateData = TagUpdate(name: name, color: color.toHex());
        await updateTagMutation.run(
          ref,
          (tsx) => tsx
              .get(tagGroupsRawProvider.notifier)
              .updateTag(widget.tag!.id, updateData),
        );
        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showAppSnackBar(
            '태그가 수정되었습니다',
            kind: AppNoticeKind.success,
          );
        }
      } else {
        final createData = TagCreate(
          name: name,
          color: color.toHex(),
          groupId: groupId,
        );
        await createTagMutation.run(
          ref,
          (tsx) => tsx.get(tagGroupsRawProvider.notifier).createTag(createData),
        );
        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showAppSnackBar(
            '태그가 생성되었습니다',
            kind: AppNoticeKind.success,
          );
        }
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          _isEditMode ? '태그 수정 실패: $error' : '태그 생성 실패: $error',
          kind: AppNoticeKind.error,
        );
      }
    }
  }
}

/// 태그 폼 시트를 표시하는 헬퍼 함수
///
/// 사용 예:
/// ```dart
/// showTagFormSheet(
///   context,
///   defaultGroupId: groupId,
/// );
/// ```
Future<void> showTagFormSheet(
  BuildContext context, {
  TagRead? tag,
  String? defaultGroupId,
}) {
  return showAppSheet<void>(
    context,
    builder: (context) =>
        TagFormSheet(tag: tag, defaultGroupId: defaultGroupId),
  );
}
