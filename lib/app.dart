// 앱 메인 위젯
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/config/app_config.dart';
import 'package:momeet/router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/providers/auth_provider.dart';

class MoMeetApp extends ConsumerWidget {
  const MoMeetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 인증 상태 감시 (초기화)
    final _ = ref.watch(authStateProvider);

    // GoRouter 인스턴스 가져오기
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,   // Material 위젯 내부 텍스트 번역
        GlobalWidgetsLocalizations.delegate,    // 기본 위젯의 텍스트 방향 등 설정
        GlobalCupertinoLocalizations.delegate,   // iOS 스타일 위젯 번역
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
