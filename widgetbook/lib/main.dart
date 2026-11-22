import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'main.directories.g.dart';

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
    return Widgetbook(
      directories: directories,
      appBuilder: (context, child) =>
          MaterialApp(debugShowCheckedModeBanner: false, home: child),
      addons: [
        ViewportAddon([
          AndroidViewports.samsungGalaxyS20,
          IosViewports.iPhone13,
          IosViewports.iPadAir4,
          MacosViewports.macbookPro,
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
      ],
    );
  }
}
