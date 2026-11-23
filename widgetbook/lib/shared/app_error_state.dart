import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '불러오기 실패 안내', type: AppErrorState, path: '[공통]')
Widget appErrorState(BuildContext context) {
  final knobs = context.knobs;
  final retry = knobs.boolean(label: '다시 시도', initialValue: true);
  final signOut = knobs.boolean(
    label: '로그아웃',
    description: '다시 시도 앞에 두는 다른 길(약관 화면)',
  );
  return AppErrorState(
    title: knobs.string(label: '제목', initialValue: '일정을 불러올 수 없습니다'),
    error: knobs.stringOrNull(label: '오류 내용', initialValue: '연결 시간이 초과되었습니다'),
    onRetry: retry ? () {} : null,
    secondaryLabel: signOut ? '로그아웃' : null,
    secondaryIcon: Icons.logout,
    onSecondary: signOut ? () {} : null,
  );
}
