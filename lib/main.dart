// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:momeet/core/providers/retry_policy.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:momeet/app.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/analytics/analytics_consent_bridge.dart'
    if (dart.library.js_interop) 'package:momeet/core/analytics/analytics_consent_bridge_web.dart';
import 'package:momeet/core/providers/account_scope.dart';
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

  // 웹이 아니면 동의를 메모리에만 두므로, 로그아웃해 컨테이너가 바뀌어도 같은 인스턴스를 쓴다
  final analyticsConsentBridge = createAnalyticsConsentBridge();

  runApp(
    AccountScope(
      createContainer: () => ProviderContainer(
        retry: appRetry,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          analyticsConsentBridgeProvider.overrideWithValue(
            analyticsConsentBridge,
          ),
        ],
      ),
      child: const MoMeetApp(),
    ),
  );
}
