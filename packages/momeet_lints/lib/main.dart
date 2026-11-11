import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:momeet_lints/src/auth_notifier_structure.dart';
import 'package:momeet_lints/src/no_direct_kratos_client.dart';
import 'package:momeet_lints/src/no_hardcoded_colors.dart';
import 'package:momeet_lints/src/no_manual_route_path.dart';
import 'package:momeet_lints/src/no_widget_helper_methods.dart';
import 'package:momeet_lints/src/prefer_media_query_aspect.dart';
import 'package:momeet_lints/src/no_raw_flutter_overlays.dart';
import 'package:momeet_lints/src/one_public_widget_per_file.dart';
import 'package:momeet_lints/src/duplicate_widget_tree.dart';
import 'package:momeet_lints/src/prefer_when_or_null.dart';
import 'package:momeet_lints/src/shared_ui_import_boundary.dart';
import 'package:momeet_lints/src/unused_consumer_ref.dart';
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
      ..registerWarningRule(SharedUiImportBoundary())
      ..registerWarningRule(NoRawFlutterOverlays())
      ..registerWarningRule(OnePublicWidgetPerFile())
      ..registerWarningRule(DuplicateWidgetTree())
      ..registerWarningRule(NoHardcodedColors())
      ..registerWarningRule(UnusedConsumerRef())
      ..registerWarningRule(PreferMediaQueryAspect())
      ..registerWarningRule(PreferWhenOrNull());
  }
}
