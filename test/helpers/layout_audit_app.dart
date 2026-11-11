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

/// 첫 프레임 뒤에 [open]을 한 번 불러 시트·다이얼로그를 띄운 화면. `show…` 함수로만 여는 시트를 점검할 때 쓴다.
class OpenOnStart extends StatefulWidget {
  const OpenOnStart({super.key, required this.open});

  final void Function(BuildContext context) open;

  @override
  State<OpenOnStart> createState() => _OpenOnStartState();
}

class _OpenOnStartState extends State<OpenOnStart> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.open(context);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
