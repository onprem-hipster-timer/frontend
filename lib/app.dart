/// 앱 메인 위젯
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/config/app_config.dart';
import 'package:momeet/router.dart';

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
