import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'edge_viewports.dart';
import 'main.directories.g.dart';
import 'preview_router.dart';

void main() {
  runApp(const MoMeetWidgetbook());
}

/// 앱 위젯은 material_ui의 Theme·MaterialLocalizations를 찾으므로, Widgetbook의 MaterialApp·
/// MaterialThemeAddon(flutter/material) 대신 material_ui 것으로 감싼다.
@widgetbook.App()
class MoMeetWidgetbook extends StatelessWidget {
  const MoMeetWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return CatalogRoot(
      child: Widgetbook(
        directories: labelSingleUseCases(directories),
        appBuilder: widgetbookAppBuilder,
        addons: widgetbookAddons,
      ),
    );
  }
}

/// use case가 하나뿐인 컴포넌트는 메뉴에 그 use case 이름과 클래스 이름으로 보인다(예: '추천 시간 카드 (MeetingSlotCard)').
/// 여럿인 컴포넌트는 클래스 이름 그대로다.
List<WidgetbookNode> labelSingleUseCases(List<WidgetbookNode> nodes) => [
  for (final node in nodes)
    switch (node) {
      WidgetbookComponent(useCases: [final only]) => WidgetbookComponent(
        name: '${only.name} (${node.name})',
        isInitiallyExpanded: node.isInitiallyExpanded,
        useCases: [
          WidgetbookUseCase(
            name: only.name,
            builder: only.builder,
            designLink: only.designLink,
          ),
        ],
      ),
      WidgetbookComponent() || WidgetbookUseCase() => node,
      _ => node.copyWith(children: labelSingleUseCases(node.children ?? [])),
    },
];

/// 앱 이미지 키(`assets/...`)를 카탈로그 번들 안의 키(`packages/momeet/assets/...`)로 바꿔 읽는다
class _AppAssetBundle extends AssetBundle {
  static String _key(String key) =>
      key.startsWith('assets/') ? 'packages/momeet/$key' : key;

  @override
  Future<ByteData> load(String key) => rootBundle.load(_key(key));

  @override
  Future<ImmutableBuffer> loadBuffer(String key) =>
      rootBundle.loadBuffer(_key(key));

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      rootBundle.loadString(_key(key), cache: cache);

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) => rootBundle.loadStructuredData(_key(key), parser);

  @override
  Future<T> loadStructuredBinaryData<T>(
    String key,
    FutureOr<T> Function(ByteData data) parser,
  ) => rootBundle.loadStructuredBinaryData(_key(key), parser);
}

final _appAssets = _AppAssetBundle();

Widget widgetbookAppBuilder(BuildContext context, Widget child) {
  // 앱의 main처럼 시간대 DB를 읽어 둔다(모임 시간표가 tz.getLocation을 쓴다)
  if (!tz.timeZoneDatabase.isInitialized) tz.initializeTimeZones();
  return DefaultAssetBundle(
    bundle: _appAssets,
    child: MaterialApp(debugShowCheckedModeBanner: false, home: child),
  );
}

final widgetbookAddons = <WidgetbookAddon>[
  ViewportAddon([
    AndroidViewports.samsungGalaxyS20,
    IosViewports.iPhone13,
    IosViewports.iPadAir4,
    MacosViewports.macbookPro,
    ...edgeViewports,
  ]),
  ThemeAddon<ThemeData>(
    themes: [
      WidgetbookTheme(name: '라이트 모드', data: AppTheme.light()),
      WidgetbookTheme(name: '다크 모드', data: AppTheme.dark()),
    ],
    themeBuilder: (context, theme, child) => Theme(
      data: theme,
      child: Material(color: theme.scaffoldBackgroundColor, child: child),
    ),
  ),
  TextScaleAddon(min: 1, max: 2, divisions: 4),
  // lib/app.dart와 같은 언어·delegate
  LocalizationAddon(
    locales: const [Locale('ko', 'KR'), Locale('en', 'US')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  ),
  // 맨 안쪽에 두어 위의 테마·뷰포트·언어가 use case와 앱 화면 안내에 함께 걸린다. 설정 칸은 없다
  BuilderAddon(name: '화면 이동', builder: catalogRouter),
];
