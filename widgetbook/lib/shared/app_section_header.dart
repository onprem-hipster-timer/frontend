import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '소제목', type: AppSectionHeader, path: '[공통]/입력 양식')
Widget appSectionHeader(BuildContext context) {
  final knobs = context.knobs;
  final title = knobs.string(label: '제목', initialValue: '태그');
  final button = knobs.boolean(
    label: '오른쪽 버튼',
    description: '할 일 입력 시트의 태그 칸처럼 소제목 끝에 두는 버튼',
    initialValue: true,
  );
  // 앱에서는 입력 시트 안, 좌우 여백 24 안쪽에 놓인다
  return Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: AppSectionHeader(
        title,
        trailing: button
            ? TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('새 태그'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              )
            : null,
      ),
    ),
  );
}
