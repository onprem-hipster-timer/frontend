import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/domain/terms.dart';

void main() {
  group('받침에 맞는 조사', () {
    test('받침이 있으면 앞의 조사, 없으면 뒤의 조사를 붙인다', () {
      expect('그룹'.withJosa('을', '를'), '그룹을');
      expect('타이머'.withJosa('을', '를'), '타이머를');
      expect('할 일'.withJosa('이', '가'), '할 일이');
      expect('타이머'.withJosa('이', '가'), '타이머가');
      expect('집중'.withJosa('은', '는'), '집중은');
      expect('휴식'.withJosa('은', '는'), '휴식은');
    });

    test('ㄹ 받침은 으로가 아니라 로를 붙인다', () {
      expect('할 일'.withJosa('으로', '로'), '할 일로');
      expect('서울'.withJosa('으로서', '로서'), '서울로서');
    });

    test('ㄹ이 아닌 받침은 으로를 붙인다', () {
      expect('집'.withJosa('으로', '로'), '집으로');
      expect('타이머'.withJosa('으로', '로'), '타이머로');
    });

    test('ㄹ 받침이라도 으로가 아닌 조사는 받침 있음으로 고른다', () {
      expect('할 일'.withJosa('을', '를'), '할 일을');
      expect('할 일'.withJosa('과', '와'), '할 일과');
    });

    test('끝의 따옴표·괄호·공백은 건너뛰고 그 앞 글자로 고른다', () {
      expect('"업무"'.withJosa('을', '를'), '"업무"를');
      expect('(공부)'.withJosa('이', '가'), '(공부)가');
      expect('보고서 '.withJosa('을', '를'), '보고서 를');
    });
  });

  group('받침을 알 수 없는 말', () {
    test('한글로 끝나지 않으면 두 형태를 함께 적는다', () {
      expect('TODO'.withJosa('을', '를'), 'TODO을(를)');
      expect('v2'.withJosa('이', '가'), 'v2이(가)');
    });

    test('으로·로는 (으)로로 적는다', () {
      expect('v2'.withJosa('으로', '로'), 'v2(으)로');
    });

    test('빈 말에는 두 형태만 붙는다', () {
      expect(''.withJosa('이', '가'), '이(가)');
      expect('  '.withJosa('을', '를'), '  을(를)');
    });
  });
}
