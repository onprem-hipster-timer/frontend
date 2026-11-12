import 'dart:async';

import 'package:layout_audit/layout_audit.dart';

import 'helpers/layout_audit_policy.dart';

/// 모든 위젯 테스트가 끝나면 화면에 남은 글자·이미지의 겹침·넘침·잘림을 점검해 보고한다.
///
/// `--dart-define=LAYOUT_AUDIT=false`면 점검하지 않는다. CI는 main으로 가는 PR에서만 점검한다.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LayoutAuditBinding.ensureInitialized(
    config: LayoutAuditConfig(
      enabled: const bool.fromEnvironment('LAYOUT_AUDIT', defaultValue: true),
      policy: appLayoutAuditPolicy,
    ),
  );
  await testMain();
}
