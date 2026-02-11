// Tag 모듈 Barrel Export
//
// 태그 관리 모듈의 모든 public 인터페이스를 export합니다.

// Domain Models
export 'domain/tag_group_with_tags.dart';

// Pages
export 'presentation/pages/tag_management_page.dart';

// Widgets
export 'presentation/widgets/tag_form_sheet.dart';
export 'presentation/widgets/tag_group_form_sheet.dart';

// Providers
export 'presentation/providers/tag_providers.dart';

// Utils (기존 color_utils는 features 레벨에 있었지만, core로 이동)
export 'presentation/utils/color_utils.dart';
