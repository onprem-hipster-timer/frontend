import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_shared.dart';

@widgetbook.UseCase(name: '입력 시트', type: AppFormSheet, path: '[공통]/입력 양식')
Widget appFormSheet(BuildContext context) {
  final knobs = context.knobs;
  final title = knobs.string(label: '제목', initialValue: '새 할 일 만들기');
  final many = knobs.boolean(
    label: '칸이 많음',
    description: '칸이 화면보다 많으면 시트가 화면 위쪽까지 올라오고 안을 굴린다',
  );
  final busy = knobs.boolean(label: '저장 중');
  // 칸은 앱의 할 일 입력 시트와 같은 모양으로 채운다
  return SheetPreview(
    child: AppFormSheet(
      title: title,
      actions: AppFormActionBar(
        submitLabel: '생성',
        onSubmit: () {},
        onCancel: () {},
        busy: busy,
      ),
      children: [
        TextFormField(
          initialValue: '장보기',
          decoration: const InputDecoration(
            labelText: '할 일 제목',
            prefixIcon: Icon(Icons.task_alt),
          ),
        ),
        if (many)
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              label: Text('설명 (선택사항)'),
              hintText: '상세 설명을 입력하세요',
              prefixIcon: Icon(Icons.notes),
              alignLabelWithHint: true,
            ),
          ),
        if (many)
          AppPickerField(
            label: '해야 할 일 목록',
            icon: Icons.folder_outlined,
            value: '기본 목록',
            onTap: () {},
          ),
        AppPickerField(
          label: '마감일',
          icon: Icons.calendar_today,
          value: '2026년 3월 2일',
          placeholder: '선택 안 함',
          onTap: () {},
          onClear: () {},
        ),
        if (many)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              const AppSectionHeader('태그'),
              Wrap(
                spacing: 8,
                children: [
                  for (final (tag, selected) in const [
                    ('운동', true),
                    ('공부', false),
                    ('집안일', false),
                  ])
                    FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (_) {},
                    ),
                ],
              ),
            ],
          ),
      ],
    ),
  );
}
