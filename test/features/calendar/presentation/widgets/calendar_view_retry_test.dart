import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/schedule_fixtures.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  testWidgets('일정을 불러오지 못한 뒤 다시 시도하면 달력을 그린다', (tester) async {
    final schedules = FakeSchedulesClient([
      makeSchedule(
        title: '회의',
        startTime: DateTime(2026, 11, 9, 9).toUtc(),
        endTime: DateTime(2026, 11, 9, 10).toUtc(),
      ),
    ])..readError = Exception('끊김');
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: [
          schedulesApiProvider.overrideWithValue(schedules),
          calendarSettingsProvider.overrideWith(_FixedSettings.new),
          currentHolidaysProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          locale: Locale('ko', 'KR'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('ko', 'KR'), Locale('en', 'US')],
          home: Scaffold(body: CalendarViewWidget()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('일정을 불러올 수 없습니다'), findsOneWidget);

    schedules.readError = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('일정을 불러올 수 없습니다'), findsNothing);
    expect(find.textContaining('회의'), findsWidgets);
  });
}

class _FixedSettings extends CalendarSettings {
  @override
  CalendarSettingsState build() => CalendarSettingsState(
    selectedDate: DateTime(2026, 11, 9),
    displayDate: DateTime(2026, 11, 9),
    firstDayOfWeek: DateTime.sunday,
  );
}
