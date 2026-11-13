import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/visibility/domain/email_allow_list.dart';

void main() {
  late EmailAllowList list;

  setUp(() => list = EmailAllowList());

  test('이메일과 도메인을 나눠 넣는다', () {
    final rejects = list.add('kim@partner.com');
    list.add('company.co.kr');

    expect(rejects.invalid, isEmpty);
    expect(rejects.duplicate, isEmpty);
    expect(list.emails, ['kim@partner.com']);
    expect(list.domains, ['company.co.kr']);
  });

  test('앞뒤 공백을 지우고 소문자로 맞추고, 도메인 앞의 @는 뗀다', () {
    list.add('  Kim@Partner.COM ');
    list.add('@Company.com');

    expect(list.emails, ['kim@partner.com']);
    expect(list.domains, ['company.com']);
  });

  test('쉼표·세미콜론·공백·줄바꿈으로 여러 개를 한 번에 넣는다', () {
    list.add('a@x.com, b@x.com;c.org\nd.net  e@y.io');

    expect(list.emails, ['a@x.com', 'b@x.com', 'e@y.io']);
    expect(list.domains, ['c.org', 'd.net']);
  });

  test('이미 있는 것은 대소문자가 달라도 넣지 않고 돌려준다', () {
    list.add('kim@partner.com company.com');
    final rejects = list.add('KIM@partner.com @COMPANY.com new.com');

    expect(rejects.duplicate, ['KIM@partner.com', '@COMPANY.com']);
    expect(rejects.invalid, isEmpty);
    expect(list.emails, ['kim@partner.com']);
    expect(list.domains, ['company.com', 'new.com']);
  });

  test('한 번에 넣는 것끼리 겹쳐도 하나만 넣는다', () {
    final rejects = list.add('a@x.com a@x.com');

    expect(list.emails, ['a@x.com']);
    expect(rejects.duplicate, ['a@x.com']);
  });

  for (final input in [
    'kim',
    'kim@',
    '@',
    'kim@partner',
    'kim@@partner.com',
    'a@b@c.com',
    'kim@partner.c',
    'partner.123',
    '-bad.com',
    'bad-.com',
    'bad..com',
    '.com',
    'com.',
    '김@회사.com',
    'kim@part_ner.com',
    'http://partner.com',
  ]) {
    test('형식이 틀린 "$input"은 넣지 않고 적은 그대로 돌려준다', () {
      final rejects = list.add(input);

      expect(rejects.invalid, [input]);
      expect(list.isEmpty, isTrue);
    });
  }

  test('맞는 것은 넣고 틀린 것만 돌려준다', () {
    final rejects = list.add('ok@x.com, nope, ok.com');

    expect(rejects.invalid, ['nope']);
    expect(list.emails, ['ok@x.com']);
    expect(list.domains, ['ok.com']);
  });

  test('빈 입력은 아무것도 넣지 않는다', () {
    final rejects = list.add('  , ; ');

    expect(rejects.invalid, isEmpty);
    expect(list.isEmpty, isTrue);
  });

  test('뺄 수 있다', () {
    list.add('a@x.com x.com');
    list.remove('a@x.com');
    list.remove('x.com');

    expect(list.isEmpty, isTrue);
  });

  test('처음 받은 목록은 순서대로 둔다', () {
    final loaded = EmailAllowList(emails: ['b@x.com', 'a@x.com']);

    expect(loaded.emails, ['b@x.com', 'a@x.com']);
    expect(loaded.isEmpty, isFalse);
  });
}
