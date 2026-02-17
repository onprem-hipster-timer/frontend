// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// 앱 메인 위젯
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/config/app_config.dart';
import 'package:momeet/router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MoMeetApp extends ConsumerWidget {
  const MoMeetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // GoRouter 인스턴스 가져오기
    // (routerProvider 내부에서 authProvider를 listen하여 redirect를 자동 재평가)
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
