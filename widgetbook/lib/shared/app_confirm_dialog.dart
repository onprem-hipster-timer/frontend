import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_shared.dart';

@widgetbook.UseCase(name: '확인 창', type: AppConfirmDialog, path: '[공통]/버튼·확인 창')
Widget appConfirmDialog(BuildContext context) {
  final knobs = context.knobs;
  return DialogPreview(
    child: AppConfirmDialog(
      title: knobs.string(label: '제목', initialValue: '일정 삭제'),
      content: knobs.string(
        label: '내용',
        initialValue: '"팀 주간 회의" 일정을 삭제하시겠습니까?\n되돌릴 수 없습니다.',
      ),
      cancelText: knobs.string(label: '취소 버튼', initialValue: '취소'),
      confirmText: knobs.string(label: '확인 버튼', initialValue: '삭제'),
      destructive: knobs.boolean(
        label: '되돌릴 수 없는 동작',
        description: '삭제·타이머 완료처럼 되돌릴 수 없으면 확인 버튼을 오류색으로 칠한다. 로그아웃은 끈다',
        initialValue: true,
      ),
    ),
  );
}
