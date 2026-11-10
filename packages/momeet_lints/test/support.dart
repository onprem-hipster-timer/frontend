import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ExpectedDiagnostic은 공개 export가 없다
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;

/// [content] 안 [snippet]의 첫 위치를 가리키는 린트 기대값.
///
/// 보고 범위가 [snippet]보다 짧으면(예: 생성자 이름만) [length]로 준다.
ExpectedDiagnostic lintAt(
  AnalysisRuleTest test,
  String content,
  String snippet, {
  int occurrence = 0,
  int? length,
  List<Pattern> messageContainsAll = const [],
  String? name,
}) {
  var offset = -1;
  for (var i = 0; i <= occurrence; i++) {
    offset = content.indexOf(snippet, offset + 1);
  }
  if (offset < 0) throw ArgumentError('snippet not found: $snippet');
  return test.lint(
    offset,
    length ?? snippet.length,
    messageContainsAll: messageContainsAll,
    name: name,
  );
}
