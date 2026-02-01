import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:momeet/app.dart';
import 'package:momeet/core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // Supabase 초기화
  // ============================================================
  // TODO: 환경 변수에서 읽거나 설정 파일에서 로드해야 합니다
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  if (AppConfig.enableDebugLogging) {
    print('🚀 [INIT] Initializing Supabase...');
    print('   URL: $supabaseUrl');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  if (AppConfig.enableDebugLogging) {
    print('✅ [INIT] Supabase initialized');
  }

  runApp(
    const ProviderScope(
      child: MoMeetApp(),
    ),
  );
}
