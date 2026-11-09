import 'package:analyzer/analysis_rule/rule_context.dart';

/// 지금 검사하는 파일의 경로(구분자는 `/`).
String currentPath(RuleContext context) =>
    (context.currentUnit?.file.path ?? '').replaceAll('\\', '/');

/// 패키지 루트 기준 상대 경로(예: `lib/app.dart`). 패키지 밖이면 절대 경로.
String packageRelativePath(RuleContext context) {
  final path = currentPath(context);
  final root = context.package?.root.path.replaceAll('\\', '/');
  if (root == null || !path.startsWith('$root/')) return path;
  return path.substring(root.length + 1);
}

/// 패키지의 `test/` 아래 파일인지.
bool isTestFile(RuleContext context) =>
    packageRelativePath(context).startsWith('test/');
