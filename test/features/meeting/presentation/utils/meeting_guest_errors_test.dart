import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_guest_errors.dart';

import '../../../../helpers/kratos_mocks.dart';

void main() {
  group('newGuestPasswordProblem', () {
    for (final (password, expected) in [
      ('', GuestRefusal.passwordTooShort),
      ('123', GuestRefusal.passwordTooShort),
      (' 12', GuestRefusal.passwordTooShort),
      ('   ', GuestRefusal.passwordBlank),
      ('    ', GuestRefusal.passwordBlank),
      ('  　\n', GuestRefusal.passwordBlank),
    ]) {
      test('${_show(password)} → $expected', () {
        final problem = newGuestPasswordProblem(password);

        expect(problem, isNotNull);
        expect(GuestRefusal.of(problem!), expected);
      });
    }

    for (final password in ['1234', ' a1 ', '가나다라', '​​​​']) {
      test('${_show(password)} → 보낼 수 있다', () {
        expect(newGuestPasswordProblem(password), isNull);
      });
    }
  });

  group('비밀번호 칸 검사 오류(422)', () {
    final rejected = DioException(
      requestOptions: RequestOptions(path: '/v1/guests'),
      response: Response(
        requestOptions: RequestOptions(path: '/v1/guests'),
        statusCode: 422,
        data: {
          'detail': [
            {
              'loc': ['body', 'password'],
              'msg': 'Value error',
            },
          ],
        },
      ),
    );

    test('보낸 비밀번호가 공백뿐이면 공백 알림이다', () {
      expect(
        guestPasswordRefusalText('    ', rejected),
        guestPasswordBlankText,
      );
    });

    test('보낸 비밀번호가 짧으면 길이 알림이다', () {
      expect(
        guestPasswordRefusalText('12', rejected),
        guestPasswordTooShortText,
      );
    });

    test('틀린 비밀번호는 짧거나 공백뿐이어도 틀렸다는 알림이다', () {
      for (final password in ['12', '    ']) {
        expect(
          guestPasswordRefusalText(password, kratosError(4000006)),
          '비밀번호가 맞지 않습니다',
        );
      }
    });

    test('보낸 비밀번호로는 까닭을 모르면 길이 알림이다', () {
      expect(
        guestPasswordRefusalText('1234', rejected),
        guestPasswordTooShortText,
      );
    });
  });
}

String _show(String text) => text.runes
    .map((rune) => 'U+${rune.toRadixString(16).padLeft(4, '0')}')
    .join(' ');
