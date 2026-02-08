import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:momeet/app.dart';
import 'package:momeet/core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/.env");

  // ============================================================
  // Supabase 초기화
  // ============================================================

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env["SUPABASE_ANON_KEY"] ?? '';

  if (AppConfig.enableDebugLogging) {
    debugPrint('🚀 [INIT] Initializing Supabase...');
    debugPrint('   URL: $supabaseUrl');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  if (AppConfig.enableDebugLogging) {
    debugPrint('✅ [INIT] Supabase initialized');
  }

  runApp(
    const ProviderScope(
      child: MoMeetApp(),
    ),
  );
}
