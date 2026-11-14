/// 화면에서 개념을 부르는 이름. 같은 개념은 어디서나 이 이름 하나로 부른다.
///
/// 문구에는 이 이름을 보간해 넣고, 이름 바로 뒤에 조사가 오면 [KoreanJosa.withJosa]로 고른다.
/// 그래야 이름을 바꿀 때 이 파일만 고치면 된다.
abstract final class Terms {
  static const todo = '할 일';

  /// 할 일을 담는 묶음. 할 일은 반드시 하나에 속한다
  static const todoGroup = '해야 할 일 목록';

  /// [todoGroup]의 짧은 이름. 온 이름이 들어가지 않는 좁은 자리에만 쓴다
  static const todoGroupShort = '할 일 목록';

  /// [todoGroup]을 가리키는 말. 문맥상 어느 목록인지 이미 분명한 자리에만 쓴다
  static const list = '목록';

  /// 태그를 묶는 묶음
  static const tagGroup = '태그 그룹';

  static const timer = '타이머';

  /// 타이머의 집중 시간. [rest]의 짝
  static const focus = '집중';
  static const rest = '휴식';

  /// 타이머를 끝내는 동작
  static const complete = '완료';
}

const _hangulFirst = 0xAC00;
const _hangulLast = 0xD7A3;

/// 받침 없음을 뺀 종성 순서에서 ㄹ의 자리
const _rieulFinal = 8;

/// 조사를 고를 때 건너뛰는 끝 글자(공백, 닫는 따옴표·괄호)
const _closers = " \t\n'\")]}’”」』》〉";

/// 앞말의 받침에 맞춰 조사를 고른다.
extension KoreanJosa on String {
  /// 이 말 뒤에 조사를 붙인다. 마지막 한글 음절에 받침이 있으면 [withFinal], 없으면 [withoutFinal]을 붙인다.
  ///
  /// 끝의 공백·따옴표·괄호는 건너뛰고 판단한다(`'"업무"'`는 '무'로).
  /// '으로'로 시작하는 조사에서는 ㄹ 받침을 받침 없음으로 친다('할 일로').
  /// 한글 음절로 끝나지 않으면 둘을 함께 적는다('TODO을(를)', 'v2(으)로').
  ///
  /// 테스트: test/shared/domain/terms_test.dart
  String withJosa(String withFinal, String withoutFinal) {
    final syllable = _lastSyllable(this);
    if (syllable == null) return '$this${_bothForms(withFinal, withoutFinal)}';
    final finalIndex = (syllable - _hangulFirst) % 28;
    final rieulAsOpen = finalIndex == _rieulFinal && withFinal.startsWith('으로');
    final hasFinal = finalIndex != 0 && !rieulAsOpen;
    return '$this${hasFinal ? withFinal : withoutFinal}';
  }
}

/// [word]의 마지막 글자. 끝의 공백·닫는 따옴표·괄호는 건너뛰고, 그 글자가 한글 음절이 아니면 null
int? _lastSyllable(String word) {
  final runes = word.runes.toList();
  for (var i = runes.length - 1; i >= 0; i--) {
    final rune = runes[i];
    if (_closers.runes.contains(rune)) continue;
    return rune >= _hangulFirst && rune <= _hangulLast ? rune : null;
  }
  return null;
}

/// 받침을 알 수 없을 때 쓰는 두 형태 병기. '으로'/'로'는 '(으)로'
String _bothForms(String withFinal, String withoutFinal) =>
    withFinal == '으$withoutFinal'
    ? '(으)$withoutFinal'
    : '$withFinal($withoutFinal)';
