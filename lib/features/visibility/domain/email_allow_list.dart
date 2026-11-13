/// 공유를 허용할 이메일과 도메인. 넣은 순서를 지킨다
///
/// 넣을 때 앞뒤 공백을 지우고 소문자로 맞춘다. 도메인 앞의 `@`는 뗀다.
///
/// 테스트: test/features/visibility/domain/email_allow_list_test.dart
class EmailAllowList {
  EmailAllowList({
    Iterable<String> emails = const [],
    Iterable<String> domains = const [],
  }) : _emails = [...emails],
       _domains = [...domains];

  final List<String> _emails;
  final List<String> _domains;

  List<String> get emails => List.unmodifiable(_emails);
  List<String> get domains => List.unmodifiable(_domains);

  bool get isEmpty => _emails.isEmpty && _domains.isEmpty;

  /// [input]을 쉼표·세미콜론·공백으로 나눠 이메일과 도메인으로 넣는다
  ///
  /// 형식이 틀린 조각은 [AllowListRejects.invalid]로, 이미 있는 것은 [AllowListRejects.duplicate]로
  /// 돌려주고 넣지 않는다. 조각은 적은 그대로 돌려준다.
  AllowListRejects add(String input) {
    final invalid = <String>[];
    final duplicate = <String>[];
    for (final piece in input.split(RegExp(r'[\s,;]+'))) {
      if (piece.isEmpty) continue;
      final entry = piece.toLowerCase();
      if (_isEmail(entry)) {
        _addTo(_emails, entry, piece, duplicate);
      } else if (_isDomain(_withoutAt(entry))) {
        _addTo(_domains, _withoutAt(entry), piece, duplicate);
      } else {
        invalid.add(piece);
      }
    }
    return (invalid: invalid, duplicate: duplicate);
  }

  /// 이메일이나 도메인 [entry]를 뺀다
  void remove(String entry) {
    _emails.remove(entry);
    _domains.remove(entry);
  }

  static void _addTo(
    List<String> list,
    String entry,
    String piece,
    List<String> duplicate,
  ) {
    if (list.contains(entry)) {
      duplicate.add(piece);
    } else {
      list.add(entry);
    }
  }

  static String _withoutAt(String entry) =>
      entry.startsWith('@') ? entry.substring(1) : entry;

  static final _localPart = RegExp(r"^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+$");
  static final _label = RegExp(r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?$');
  static final _topLabel = RegExp(r'^[a-z]{2,}$');

  static bool _isEmail(String entry) {
    final at = entry.indexOf('@');
    if (at <= 0 || at != entry.lastIndexOf('@')) return false;
    return _localPart.hasMatch(entry.substring(0, at)) &&
        _isDomain(entry.substring(at + 1));
  }

  /// 점으로 나뉜 두 단계 이상이고 마지막은 글자 두 개 이상
  static bool _isDomain(String entry) {
    final labels = entry.split('.');
    return labels.length >= 2 &&
        labels.every((label) => label.length <= 63 && _label.hasMatch(label)) &&
        _topLabel.hasMatch(labels.last);
  }
}

/// [EmailAllowList.add]가 넣지 못한 조각
typedef AllowListRejects = ({List<String> invalid, List<String> duplicate});
