import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/network/explicit_null_interceptor.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/features/tag/presentation/utils/tag_color_palette.dart';
import 'package:momeet/features/tag/presentation/widgets/group_form_fields.dart';
import 'package:momeet/features/todo/presentation/providers/todo_group_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 할 일 그룹 생성/수정 폼 시트. 칸은 [GroupFormFields]
class TodoGroupFormSheet extends ConsumerStatefulWidget {
  /// 수정할 할 일 그룹 (null이면 생성)
  final TodoGroupRead? group;

  const TodoGroupFormSheet({super.key, this.group});

  @override
  ConsumerState<TodoGroupFormSheet> createState() => _TodoGroupFormSheetState();
}

class _TodoGroupFormSheetState extends ConsumerState<TodoGroupFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.group?.name);
  late final _descriptionController = TextEditingController(
    text: widget.group?.description,
  );
  late var _color = widget.group == null
      ? TagColorPalette.defaultColor
      : HexColor.fromHex(widget.group!.color);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.group != null;
    final isLoading = isEditMode
        ? ref.watch(updateTodoGroupMutation).isPending
        : ref.watch(createTodoGroupMutation).isPending;
    return AppFormSheet(
      title: isEditMode ? '${Terms.todoGroup} 수정' : '새 ${Terms.todoGroup} 만들기',
      formKey: _formKey,
      actions: AppFormActionBar(
        submitLabel: isEditMode ? '수정' : '생성',
        onSubmit: _handleSubmit,
        busy: isLoading,
      ),
      children: [
        GroupFormFields(
          noun: Terms.todoGroup,
          nameController: _nameController,
          descriptionController: _descriptionController,
          color: _color,
          onColorChanged: (color) => setState(() => _color = color),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final group = widget.group;
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    try {
      if (group != null) {
        await updateTodoGroupMutation.run(
          ref,
          (tsx) => tsx
              .get(todoGroupsProvider.notifier)
              .updateGroup(
                group.id,
                TodoGroupUpdate(
                  name: name,
                  color: _color.toHex(),
                  description: description.isEmpty ? null : description,
                ),
                options: description.isEmpty
                    ? explicitNulls(['description'])
                    : null,
              ),
        );
      } else {
        await createTodoGroupMutation.run(
          ref,
          (tsx) => tsx
              .get(todoGroupsProvider.notifier)
              .createGroup(
                TodoGroupCreate(
                  name: name,
                  color: _color.toHex(),
                  description: description.isEmpty ? null : description,
                ),
              ),
        );
      }
      if (!mounted) return;
      navigator.pop();
      messenger.showAppSnackBar(
        group != null
            ? '${Terms.todoGroup.withJosa('이', '가')} 수정되었습니다'
            : '${Terms.todoGroup.withJosa('이', '가')} 생성되었습니다',
        kind: AppNoticeKind.success,
      );
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        group != null
            ? '${Terms.todoGroup} 수정에 실패했습니다: $error'
            : '${Terms.todoGroup} 생성에 실패했습니다: $error',
        kind: AppNoticeKind.error,
      );
    }
  }
}

/// 할 일 그룹 폼 시트를 연다. [group]을 주면 수정, 아니면 생성
Future<void> showTodoGroupFormSheet(
  BuildContext context, {
  TodoGroupRead? group,
}) {
  return showAppSheet<void>(
    context,
    builder: (context) => TodoGroupFormSheet(group: group),
  );
}
