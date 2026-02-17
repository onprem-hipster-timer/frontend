// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:momeet/app.dart';
import 'package:momeet/core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // Intl Locale 초기화 (DateFormat 사용을 위해 필요)
  // ============================================================
  await initializeDateFormatting('ko_KR', null);
  await initializeDateFormatting('en_US', null);

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
