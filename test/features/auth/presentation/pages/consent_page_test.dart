import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/config/legal_links.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';
import 'package:momeet/features/auth/presentation/pages/consent_page.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/kratos_mocks.dart';
import '../../../../helpers/pump_app.dart';

const _age = '[필수] 만 14세 이상입니다';
const _terms = '[필수] 이용약관 동의';
const _privacy = '[필수] 개인정보 수집·이용 동의';
const _analytics = '[선택] 화면 개선을 위한 사용성 분석 동의';
const _all = '전체 동의';
const _submit = '동의하고 시작하기';

void main() {
  late KratosTestHarness harness;
  late FakeUsersClient users;
  late InMemoryAnalyticsConsentBridge analytics;
  late List<Uri> opened;

  setUpAll(registerKratosFallbacks);

  setUp(() async {
    harness = await KratosTestHarness.create();
    users = FakeUsersClient();
    analytics = InMemoryAnalyticsConsentBridge();
    opened = [];
  });

  Future<ProviderContainer> pumpConsent(WidgetTester tester) async {
    await tester.pumpWidget(
      pumpApp(
        const ConsentPage(),
        overrides: [
          ...harness.overrides,
          usersApiProvider.overrideWithValue(users),
          analyticsConsentBridgeProvider.overrideWithValue(analytics),
          openLinkProvider.overrideWithValue((url) async => opened.add(url)),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(ConsentPage)));
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  bool checked(WidgetTester tester, String label) => tester
      .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, label))
      .value!;

  bool submitEnabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, _submit))
          .onPressed !=
      null;

  Future<void> checkRequired(WidgetTester tester) async {
    for (final label in [_age, _terms, _privacy]) {
      await tapText(tester, label);
    }
  }

  testWidgets('선택 항목은 무엇을 누구에게 얼마나 보내는지와 입력이 가려지고 거부해도 된다는 것을 짧게 적는다', (
    tester,
  ) async {
    await pumpConsent(tester);

    expect(
      find.text(
        '화면 이용 기록이 Microsoft Clarity(미국)로 전송되어 최대 9개월 보관됩니다. '
        '입력한 내용은 가려지고, 거부해도 이용에 제한이 없습니다.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('클릭'), findsNothing);
    expect(find.textContaining('재현'), findsNothing);
  });

  group('필수 항목', () {
    testWidgets('필수 세 항목을 모두 체크해야 시작할 수 있다', (tester) async {
      await pumpConsent(tester);
      expect(submitEnabled(tester), isFalse);

      // 순서와 상관없이 마지막 필수 항목을 체크할 때 켜진다
      await tapText(tester, _privacy);
      expect(submitEnabled(tester), isFalse);
      await tapText(tester, _age);
      expect(submitEnabled(tester), isFalse);
      await tapText(tester, _terms);
      expect(submitEnabled(tester), isTrue);

      // 하나라도 풀면 다시 꺼진다
      await tapText(tester, _age);
      expect(submitEnabled(tester), isFalse);
    });

    testWidgets('선택 항목은 시작을 막지도, 대신하지도 않는다', (tester) async {
      await pumpConsent(tester);

      await tapText(tester, _analytics);
      expect(submitEnabled(tester), isFalse);

      await checkRequired(tester);
      await tapText(tester, _analytics);
      expect(checked(tester, _analytics), isFalse);
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('전체 동의는 선택 항목까지 모두 켜고, 다시 누르면 모두 끈다', (tester) async {
      await pumpConsent(tester);

      await tapText(tester, _all);
      for (final label in [_age, _terms, _privacy, _analytics]) {
        expect(checked(tester, label), isTrue, reason: label);
      }
      expect(submitEnabled(tester), isTrue);

      await tapText(tester, _all);
      for (final label in [_age, _terms, _privacy, _analytics]) {
        expect(checked(tester, label), isFalse, reason: label);
      }
      expect(submitEnabled(tester), isFalse);
    });

    testWidgets('필수만 체크하면 전체 동의는 꺼져 있다', (tester) async {
      await pumpConsent(tester);
      await checkRequired(tester);

      expect(checked(tester, _all), isFalse);
    });
  });

  group('제출', () {
    testWidgets('프로필이 알려 준 약관 버전으로 세 항목 동의와 사용성 분석 선택을 한 요청으로 보낸다', (
      tester,
    ) async {
      users = FakeUsersClient(consentVersion: '2026-11-19');
      final container = await pumpConsent(tester);

      await checkRequired(tester);
      await tapText(tester, _submit);

      expect(users.agreed, [
        const ConsentCreate(
          version: '2026-11-19',
          ageOver14: true,
          terms: true,
          privacy: true,
          analytics: false,
        ),
      ]);
      expect(container.read(consentRequiredProvider), isFalse);
    });

    testWidgets('선택 항목을 체크하지 않고 시작하면 계정에 거부로 보내고 이 브라우저도 거부한다', (tester) async {
      await pumpConsent(tester);

      await checkRequired(tester);
      await tapText(tester, _submit);

      expect(users.agreed.single.analytics, isFalse);
      expect(users.profile.analyticsConsent, isFalse);
      expect(analytics.current, AnalyticsConsent.denied);
    });

    testWidgets('선택 항목을 체크하고 시작하면 계정에 허용으로 보내고 이 브라우저도 허용한다', (tester) async {
      await pumpConsent(tester);

      await tapText(tester, _all);
      await tapText(tester, _submit);

      expect(users.agreed.single.analytics, isTrue);
      expect(analytics.current, AnalyticsConsent.granted);
    });

    testWidgets('동의를 저장하지 못하면 이 브라우저의 사용성 분석 값도 바꾸지 않는다', (tester) async {
      users.consentError = Exception('끊김');
      await pumpConsent(tester);

      await tapText(tester, _all);
      await tapText(tester, _submit);

      expect(users.agreed, hasLength(1));
      expect(analytics.current, isNull);
    });

    testWidgets('이미 사용성 분석을 허용했으면 선택 항목이 체크된 채로 시작한다', (tester) async {
      analytics = InMemoryAnalyticsConsentBridge(AnalyticsConsent.granted);
      await pumpConsent(tester);

      expect(checked(tester, _analytics), isTrue);
    });

    testWidgets('보내는 중에는 다시 보낼 수 없다', (tester) async {
      final gate = Completer<void>();
      users.consentGate = gate.future;
      await pumpConsent(tester);
      await checkRequired(tester);

      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      gate.complete();
      await tester.pumpAndSettle();

      expect(users.agreed, hasLength(1));
    });
  });

  group('실패', () {
    testWidgets('약관이 바뀌었으면(409) 프로필을 다시 받고 처음부터 다시 동의하게 한다', (tester) async {
      await pumpConsent(tester);
      await checkRequired(tester);
      users.consentError = httpError('/v1/users/me/consent', 409);
      users.profile = users.profile.copyWith(consentVersion: '2027-02-01');

      await tapText(tester, _submit);

      expect(find.textContaining('약관이 바뀌었습니다'), findsOneWidget);
      expect(users.reads, 2);
      for (final label in [_age, _terms, _privacy]) {
        expect(checked(tester, label), isFalse, reason: label);
      }
      expect(submitEnabled(tester), isFalse);

      // 다시 동의하면 새 버전으로 보낸다
      users.consentError = null;
      await checkRequired(tester);
      await tapText(tester, _submit);
      expect(users.agreed.last.version, '2027-02-01');
    });

    testWidgets('그 밖의 실패는 알리고 체크를 그대로 둔다', (tester) async {
      final container = await pumpConsent(tester);
      await checkRequired(tester);
      users.consentError = httpError('/v1/users/me/consent', 500);

      await tapText(tester, _submit);

      expect(find.textContaining('동의 저장에 실패했습니다'), findsOneWidget);
      expect(checked(tester, _terms), isTrue);
      expect(submitEnabled(tester), isTrue);
      expect(container.read(consentRequiredProvider), isTrue);
    });

    testWidgets('프로필을 불러오지 못하면 알리고, 다시 시도하면 동의 화면을 연다', (tester) async {
      users.readError = httpError('/v1/users/me', 500);
      await pumpConsent(tester);

      expect(find.text('약관 정보를 불러오지 못했습니다'), findsOneWidget);
      expect(find.text(_submit), findsNothing);

      users.readError = null;
      await tapText(tester, '다시 시도');

      expect(find.text(_submit), findsOneWidget);
    });
  });

  group('동의하지 않기', () {
    testWidgets('필수 항목 없이는 쓸 수 없다고 알리고, 누르면 로그아웃한다', (tester) async {
      when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
      final container = await pumpConsent(tester);

      expect(find.textContaining('만 14세 미만은 가입할 수 없습니다'), findsOneWidget);
      await tester.ensureVisible(find.text('동의하지 않고 로그아웃'));
      await tester.tap(find.text('동의하지 않고 로그아웃'));
      // 로그아웃하면 라우터가 이 화면을 떠나므로 여기서는 불러오기 표시만 남는다
      await tester.pump();
      await tester.pump();

      verify(() => harness.kratos.logout(KratosTestHarness.sessionToken));
      expect(container.read(isAuthenticatedProvider), isFalse);
      expect(users.agreed, isEmpty);
    });

    testWidgets('로그아웃하지 못하면 알린다', (tester) async {
      when(
        () => harness.kratos.logout(any()),
      ).thenThrow(httpError('/self-service/logout/api', 500));
      final container = await pumpConsent(tester);

      await tapText(tester, '동의하지 않고 로그아웃');

      expect(find.textContaining('로그아웃 실패'), findsOneWidget);
      expect(container.read(isAuthenticatedProvider), isTrue);
    });
  });

  testWidgets('보기는 이용약관과 개인정보처리방침을 연다', (tester) async {
    await pumpConsent(tester);

    final views = find.text('보기');
    expect(views, findsNWidgets(2));
    await tester.tap(views.at(0));
    await tester.tap(views.at(1));

    expect(opened, [LegalLinks.terms, LegalLinks.privacy]);
  });
}
