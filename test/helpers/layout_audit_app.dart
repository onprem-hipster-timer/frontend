import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:momeet/core/theme/app_colors.dart';

/// 레이아웃 점검용 앱 껍데기. 로케일·델리게이트·라이트 테마를 `lib/app.dart`와 같게 둔다.
Widget Function(Widget child) wrapWithApp({
  List<Override> overrides = const [],
}) {
  return (child) => ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      locale: const Locale('ko', 'KR'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        extensions: const [
          AppColors(success: Colors.green, onSuccess: Colors.white),
        ],
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: child),
    ),
  );
}
