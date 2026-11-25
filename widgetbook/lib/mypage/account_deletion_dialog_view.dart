import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/mypage/presentation/widgets/account_deletion_dialog_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../shared/samples_shared.dart';

@widgetbook.UseCase(
  name: '회원 탈퇴 확인 창',
  type: AccountDeletionDialogView,
  path: '[마이페이지]',
)
Widget accountDeletionDialogView(BuildContext context) {
  final submitting = context.knobs.boolean(
    label: '신청하는 중',
    description: '탈퇴 신청을 누른 뒤 끝날 때까지 체크·취소·신청을 막고 버튼에 진행 표시를 둔다',
  );
  // 앱에서는 설정 목록의 회원 탈퇴를 누르면 뜬다. 체크하면 탈퇴 신청을 누를 수 있고,
  // 취소하거나 신청을 마치면 창이 닫힌다
  return DialogPreview(
    child: AccountDeletionDialogView(
      submitting: submitting,
      onSubmit: () => Navigator.of(context).pop(),
      onCancel: () => Navigator.of(context).pop(),
    ),
  );
}
