import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:momeet_lints/src/no_direct_supabase_auth.dart';
import 'package:momeet_lints/src/auth_notifier_structure.dart';

PluginBase createPlugin() => _MomeetLints();

class _MomeetLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const NoDirectSupabaseAuth(),
        const AuthNotifierBuildStructure(),
        const AuthActionNoStateMutation(),
        const AuthCatchRequireClassify(),
      ];
}
