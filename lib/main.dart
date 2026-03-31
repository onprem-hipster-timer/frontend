// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:momeet/app.dart';
import 'package:momeet/core/config/app_config.dart';
import 'package:momeet/core/providers/shared_preferences_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // Intl Locale 초기화 (DateFormat 사용을 위해 필요)
  // ============================================================
  await initializeDateFormatting('ko_KR', null);
  await initializeDateFormatting('en_US', null);

  await dotenv.load(fileName: "assets/.env");

  // ============================================================
  // SharedPreferences 프리로드
  // ============================================================
  final prefs = await SharedPreferences.getInstance();

  // ============================================================
  // IANA Timezone DB 초기화
  // ============================================================
  tz.initializeTimeZones();

  // ============================================================
  // Supabase 초기화
  // ============================================================

  if (AppConfig.enableDebugLogging) {
    debugPrint('🚀 [INIT] Initializing Supabase...');
    debugPrint('   URL: ${AppConfig.supabaseUrl}');
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  if (AppConfig.enableDebugLogging) {
    debugPrint('✅ [INIT] Supabase initialized');
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MoMeetApp(),
    ),
  );
}
