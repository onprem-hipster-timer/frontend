import 'package:momeet/core/providers/retry_policy.dart';
import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:momeet/shared/ui/ui.dart';

/// 레이아웃 점검용 앱 껍데기. 로케일·델리게이트·라이트 테마를 `lib/app.dart`와 같게 둔다.
Widget Function(Widget child) wrapWithApp({
  List<Override> overrides = const [],
}) {
  return (child) => ProviderScope(
    retry: appRetry,
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      locale: const Locale('ko', 'KR'),
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: child),
    ),
  );
}
