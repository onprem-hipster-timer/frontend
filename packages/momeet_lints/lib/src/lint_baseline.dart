import 'package:analyzer/analysis_rule/rule_context.dart';

/// 패키지 루트의 `lint_baseline.txt`: 아직 고치지 않은 기존 위반 목록.
///
/// 한 줄에 `<규칙> <lib 상대 경로> <대상> <허용 줄 수 또는 ->`. `#`은 주석.
/// 크기 규칙은 허용 줄 수를 넘으면, 그 밖의 규칙은 목록에 없으면 위반이다.
/// 대상이 규칙을 지키게 되거나 사라지면 그 줄을 지우라고 알린다.
class LintBaseline {
  LintBaseline._(this._entries);

  static const fileName = 'lint_baseline.txt';

  /// `rule|path` → 대상 → 허용 줄 수(없으면 null)
  final Map<String, Map<String, int?>> _entries;

  static LintBaseline of(RuleContext context) {
    final root = context.package?.root;
    if (root == null) return LintBaseline._(const {});
    final file = root.getFile(fileName);
    if (!file.exists) return LintBaseline._(const {});
    return parse(file.readAsStringSync());
  }

  static LintBaseline parse(String content) {
    final entries = <String, Map<String, int?>>{};
    for (final raw in content.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length != 4) continue;
      entries.putIfAbsent('${parts[0]}|${parts[1]}', () => {})[parts[2]] =
          int.tryParse(parts[3]);
    }
    return LintBaseline._(entries);
  }

  /// 이 파일에서 [rule]에 걸린 대상들(대상 → 허용 줄 수).
  Map<String, int?> entriesFor(String rule, String path) =>
      _entries['$rule|$path'] ?? const {};
}
