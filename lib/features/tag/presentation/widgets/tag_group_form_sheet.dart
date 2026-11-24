import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/explicit_null_interceptor.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/tag_providers.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_group_form_sheet_view.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 태그 그룹 생성/수정 폼 시트. 칸은 [TagGroupFormSheetView]
class TagGroupFormSheet extends ConsumerStatefulWidget {
  /// 수정할 태그 그룹 (null인 경우 생성 모드)
  final TagGroupReadWithTags? tagGroup;

  const TagGroupFormSheet({super.key, this.tagGroup});

  @override
  ConsumerState<TagGroupFormSheet> createState() => _TagGroupFormSheetState();
}

class _TagGroupFormSheetState extends ConsumerState<TagGroupFormSheet> {
  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.tagGroup != null;
    final isLoading = isEditMode
        ? ref.watch(updateTagGroupMutation).isPending
        : ref.watch(createTagGroupMutation).isPending;

    return TagGroupFormSheetView(
      tagGroup: widget.tagGroup,
      busy: isLoading,
      onSubmit: _handleSubmit,
    );
  }

  /// 폼 제출 처리
  Future<void> _handleSubmit(
    String name,
    String description,
    Color color,
  ) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (widget.tagGroup != null) {
        // 수정 모드
        final updateData = TagGroupUpdate(
          name: name,
          color: color.toHex(),
          description: description.isEmpty ? null : description,
        );

        await updateTagGroupMutation.run(
          ref,
          (tsx) => tsx
              .get(tagGroupsRawProvider.notifier)
              .updateGroup(
                widget.tagGroup!.id,
                updateData,
                options: description.isEmpty
                    ? explicitNulls(['description'])
                    : null,
              ),
        );

        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showAppSnackBar(
            '${Terms.tagGroup.withJosa('이', '가')} 수정되었습니다',
            kind: AppNoticeKind.success,
          );
        }
      } else {
        // 생성 모드
        final createData = TagGroupCreate(
          name: name,
          color: color.toHex(),
          description: description.isEmpty ? null : description,
        );

        await createTagGroupMutation.run(
          ref,
          (tsx) =>
              tsx.get(tagGroupsRawProvider.notifier).createGroup(createData),
        );

        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showAppSnackBar(
            '${Terms.tagGroup.withJosa('이', '가')} 생성되었습니다',
            kind: AppNoticeKind.success,
          );
        }
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          widget.tagGroup != null
              ? '${Terms.tagGroup} 수정에 실패했습니다: $error'
              : '${Terms.tagGroup} 생성에 실패했습니다: $error',
          kind: AppNoticeKind.error,
        );
      }
    }
  }
}

/// 태그 그룹 폼 시트를 표시하는 헬퍼 함수
Future<void> showTagGroupFormSheet(
  BuildContext context, {
  TagGroupReadWithTags? tagGroup,
}) {
  return showAppSheet<void>(
    context,
    builder: (context) => TagGroupFormSheet(tagGroup: tagGroup),
  );
}
