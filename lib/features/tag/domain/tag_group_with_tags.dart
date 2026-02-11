import 'package:momeet/shared/api/export.dart';

/// 태그 그룹과 하위 태그들을 포함한 계층형 데이터 모델
///
/// UI에서 태그 트리를 표현하기 위해 사용됩니다.
/// OpenAPI 생성 모델들을 조합하여 계층 구조를 만듭니다.
class TagGroupWithTags {
  /// 태그 그룹 정보 (OpenAPI 생성 모델)
  final TagGroupRead group;

  /// 이 그룹에 속한 태그들 (OpenAPI 생성 모델들)
  final List<TagRead> tags;

  const TagGroupWithTags({
    required this.group,
    required this.tags,
  });

  /// 태그가 있는 그룹인지 확인
  bool get hasTags => tags.isNotEmpty;

  /// 태그 개수
  int get tagCount => tags.length;

  /// 그룹 ID (편의 getter)
  String get groupId => group.id;

  /// 그룹 이름 (편의 getter)
  String get groupName => group.name;

  /// 그룹 색상 (편의 getter)
  String get groupColor => group.color;

  /// 그룹 설명 (편의 getter)
  String? get groupDescription => group.description;

  /// Todo 그룹 여부 (편의 getter)
  bool get isTodoGroup => group.isTodoGroup;

  /// 생성일 (편의 getter)
  DateTime get createdAt => group.createdAt;

  /// 수정일 (편의 getter)
  DateTime get updatedAt => group.updatedAt;

  /// 특정 태그 ID로 태그 찾기
  TagRead? findTagById(String tagId) {
    try {
      return tags.firstWhere((tag) => tag.id == tagId);
    } catch (e) {
      return null;
    }
  }

  /// 태그 이름으로 태그 찾기
  List<TagRead> findTagsByName(String name) {
    return tags.where((tag) => 
      tag.name.toLowerCase().contains(name.toLowerCase())
    ).toList();
  }

  /// 새로운 태그 목록으로 복사본 생성
  TagGroupWithTags copyWithTags(List<TagRead> newTags) {
    return TagGroupWithTags(
      group: group,
      tags: newTags,
    );
  }

  /// 새로운 그룹 정보로 복사본 생성
  TagGroupWithTags copyWithGroup(TagGroupRead newGroup) {
    return TagGroupWithTags(
      group: newGroup,
      tags: tags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TagGroupWithTags &&
        other.group.id == group.id &&
        other.tags.length == tags.length &&
        _listEquals(other.tags, tags);
  }

  @override
  int get hashCode => group.id.hashCode ^ tags.length.hashCode;

  @override
  String toString() {
    return 'TagGroupWithTags(group: ${group.name}, tagCount: ${tags.length})';
  }

  /// 리스트 비교를 위한 헬퍼 메서드
  bool _listEquals(List<TagRead> a, List<TagRead> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}
