// Tag 모듈 Barrel Export
//
// 태그 관리 모듈의 모든 public 인터페이스를 export합니다.
//
// 참고: 태그 데이터·뮤테이션 계층(tagGroupsRaw/tagGroups/tagTree/TagMutations)과
// TagGroupWithTags 모델은 tag·todo가 공유하므로 `lib/shared/`로 이동했습니다.
//   - providers: package:momeet/shared/providers/tag_providers.dart
//   - model: package:momeet/shared/domain/tag_group_with_tags.dart

// Pages
export 'presentation/pages/tag_management_page.dart';

// Widgets
export 'presentation/widgets/tag_form_sheet.dart';
export 'presentation/widgets/tag_group_form_sheet.dart';

// Utils
export 'presentation/utils/tag_color_palette.dart';
