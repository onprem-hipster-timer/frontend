import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:momeet_lints/src/auth_notifier_structure.dart';
import 'package:momeet_lints/src/no_direct_kratos_client.dart';
import 'package:momeet_lints/src/no_manual_route_path.dart';
import 'package:momeet_lints/src/no_widget_helper_methods.dart';
import 'package:momeet_lints/src/shared_ui_import_boundary.dart';
import 'package:momeet_lints/src/widget_size_rules.dart';

final plugin = MomeetLintsPlugin();

class MomeetLintsPlugin extends Plugin {
  @override
  String get name => 'momeet_lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(NoDirectKratosClient())
      ..registerWarningRule(AuthActionNoLoadingState())
      ..registerWarningRule(AuthCatchRequireClassify())
      ..registerWarningRule(NoManualRoutePath())
      ..registerWarningRule(MaxWidgetClassLines())
      ..registerWarningRule(MaxBuildLines())
      ..registerWarningRule(MaxFileLines())
      ..registerWarningRule(NoWidgetHelperMethods())
      ..registerWarningRule(SharedUiImportBoundary());
  }
}
