import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/pages/security_warning_page.dart';

void main() {
  group('SecurityWarningPage', () {
    Widget buildPage({String? attemptedUrl}) {
      return MaterialApp(
        home: SecurityWarningPage(attemptedUrl: attemptedUrl),
      );
    }

    testWidgets('경고 아이콘과 제목이 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());

      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.text('보안 경고'), findsOneWidget);
    });

    testWidgets('허가되지 않은 리다이렉트 경고 메시지가 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());

      expect(
        find.text('허가되지 않은 리다이렉트가 감지되었습니다.'),
        findsOneWidget,
      );
    });

    testWidgets('연락처 이메일이 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());

      expect(find.text(SecurityWarningPage.contactEmail), findsOneWidget);
      expect(find.text('이메일'), findsOneWidget);
    });

    testWidgets('GitHub 레포 링크가 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());

      expect(find.text(SecurityWarningPage.repoUrl), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
    });

    testWidgets('홈으로 돌아가기 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());

      expect(find.text('홈으로 돌아가기'), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('URL 형태의 attemptedUrl은 차단 경로를 표시한다', (tester) async {
      await tester.pumpWidget(buildPage(attemptedUrl: 'https://evil.com'));

      expect(find.text('차단된 리다이렉트 경로'), findsOneWidget);
      expect(find.text('https://evil.com'), findsOneWidget);
    });

    testWidgets('경로 형태의 attemptedUrl은 차단 경로를 표시한다', (tester) async {
      await tester.pumpWidget(buildPage(attemptedUrl: '/admin/dashboard'));

      expect(find.text('차단된 리다이렉트 경로'), findsOneWidget);
      expect(find.text('/admin/dashboard'), findsOneWidget);
    });

    testWidgets('attemptedUrl이 null이면 차단 경로 영역이 표시되지 않는다', (tester) async {
      await tester.pumpWidget(buildPage(attemptedUrl: null));

      expect(find.text('차단된 리다이렉트 경로'), findsNothing);
    });

    testWidgets('attemptedUrl이 빈 문자열이면 차단 경로 영역이 표시되지 않는다', (tester) async {
      await tester.pumpWidget(buildPage(attemptedUrl: ''));

      expect(find.text('차단된 리다이렉트 경로'), findsNothing);
    });

    testWidgets('URL/경로가 아닌 임의 텍스트는 표시하지 않는다 (소셜 엔지니어링 방지)', (tester) async {
      await tester.pumpWidget(
        buildPage(attemptedUrl: '계정이 해킹되었습니다 010-1234-5678로 전화하세요'),
      );

      expect(find.text('차단된 리다이렉트 경로'), findsNothing);
    });

    testWidgets('복사 버튼을 누르면 클립보드에 복사되고 SnackBar가 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());

      final copyButtons = find.byIcon(Icons.copy);
      expect(copyButtons, findsNWidgets(2));

      await tester.tap(copyButtons.first);
      await tester.pump();

      expect(
        find.text('${SecurityWarningPage.contactEmail} 복사됨'),
        findsOneWidget,
      );
    });

    testWidgets('상수 값이 올바르다', (tester) async {
      expect(SecurityWarningPage.contactEmail, 'jjh4450git@gmail.com');
      expect(
        SecurityWarningPage.repoUrl,
        'https://github.com/onprem-hipster-timer/frontend',
      );
    });
  });

  // ============================================================
  // sanitizeBlockedUrl 단위 테스트
  // ============================================================
  group('sanitizeBlockedUrl', () {
    group('유효한 URL/경로 허용', () {
      test('https:// URL을 허용한다', () {
        expect(
          SecurityWarningPage.sanitizeBlockedUrl('https://evil.com'),
          'https://evil.com',
        );
      });

      test('http:// URL을 허용한다', () {
        expect(
          SecurityWarningPage.sanitizeBlockedUrl('http://evil.com'),
          'http://evil.com',
        );
      });

      test('ftp:// URL을 허용한다', () {
        expect(
          SecurityWarningPage.sanitizeBlockedUrl('ftp://evil.com/file'),
          'ftp://evil.com/file',
        );
      });

      test('javascript: URI를 허용한다 (차단된 경로이므로 표시 목적)', () {
        expect(
          SecurityWarningPage.sanitizeBlockedUrl('javascript:alert(1)'),
          'javascript:alert(1)',
        );
      });

      test('/ 로 시작하는 경로를 허용한다', () {
        expect(
          SecurityWarningPage.sanitizeBlockedUrl('/admin/dashboard'),
          '/admin/dashboard',
        );
      });

      test('// 로 시작하는 프로토콜 상대 URL을 허용한다', () {
        expect(
          SecurityWarningPage.sanitizeBlockedUrl('//evil.com'),
          '//evil.com',
        );
      });
    });

    group('임의 텍스트 차단 (소셜 엔지니어링 방지)', () {
      test('한글 메시지를 차단한다', () {
        expect(
          SecurityWarningPage.sanitizeBlockedUrl('계정이 해킹되었습니다'),
          isNull,
        );
      });

      test('전화번호가 포함된 피싱 메시지를 차단한다', () {
        expect(
          SecurityWarningPage.sanitizeBlockedUrl('긴급! 010-1234-5678로 전화하세요'),
          isNull,
        );
      });

      test('영문 피싱 메시지를 차단한다', () {
        expect(
          SecurityWarningPage.sanitizeBlockedUrl(
              'Your account has been compromised call now'),
          isNull,
        );
      });

      test('숫자만 있는 값을 차단한다', () {
        expect(
          SecurityWarningPage.sanitizeBlockedUrl('1234567890'),
          isNull,
        );
      });

      test('빈 문자열을 차단한다', () {
        expect(SecurityWarningPage.sanitizeBlockedUrl(''), isNull);
      });

      test('null을 차단한다', () {
        expect(SecurityWarningPage.sanitizeBlockedUrl(null), isNull);
      });
    });

    group('길이 제한 (DoS 방지)', () {
      test('200자 이내 URL은 그대로 반환한다', () {
        final url = 'https://evil.com/${'a' * 170}';
        expect(url.length, lessThanOrEqualTo(200));
        expect(
          SecurityWarningPage.sanitizeBlockedUrl(url),
          url,
        );
      });

      test('200자 초과 URL은 잘리고 ...이 붙는다', () {
        final url = 'https://evil.com/${'a' * 200}';
        expect(url.length, greaterThan(200));

        final result = SecurityWarningPage.sanitizeBlockedUrl(url);
        expect(result, isNotNull);
        expect(result!.length, 203); // 200 + '...'
        expect(result.endsWith('...'), true);
      });

      test('매우 긴 경로도 잘린다', () {
        final path = '/${'x' * 300}';
        final result = SecurityWarningPage.sanitizeBlockedUrl(path);
        expect(result!.length, 203);
      });
    });
  });
}
