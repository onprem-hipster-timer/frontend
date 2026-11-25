import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:momeet/core/config/app_config.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';

import '../../trial_harness.dart';

/// 브라우저 탭 제목으로 알린 글을 차례로 모은다
List<String> recordTitles(WidgetTester tester) {
  final titles = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'SystemChrome.setApplicationSwitcherDescription') {
      titles.add((call.arguments as Map)['label'] as String);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return titles;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  testWidgets('체험하기를 열면 탭 제목이 체험하기 제목이다', (tester) async {
    final titles = recordTitles(tester);
    await openTrial(tester);

    expect(titles.last, trialDocumentTitle);
  });

  testWidgets('체험하기에서 건너뛰기를 눌러 회원가입으로 가면 탭 제목이 앱 이름으로 돌아온다', (tester) async {
    final titles = recordTitles(tester);
    await openTrial(tester);

    await tester.tap(find.text(trialSkip));
    await tester.pumpAndSettle();

    expect(find.text(signupScreen), findsOneWidget);
    expect(titles.last, AppConfig.appName);
  });

  testWidgets('끝에서 모임 만들기를 열면 앱 이름이고, 돌아오면 다시 체험하기 제목이다', (tester) async {
    final titles = recordTitles(tester);
    await openTrial(tester);
    await goToEnd(tester);

    await tester.ensureVisible(find.text(trialMeetingAction));
    await tester.tap(find.text(trialMeetingAction));
    await tester.pumpAndSettle();
    expect(find.text(meetingsScreen), findsOneWidget);
    expect(titles.last, AppConfig.appName);

    GoRouter.of(tester.element(find.text(meetingsScreen))).pop();
    await tester.pumpAndSettle();
    expect(titles.last, trialDocumentTitle);
  });
}
