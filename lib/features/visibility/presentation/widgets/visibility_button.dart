import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 공유 범위 [level]의 아이콘. 설정이 없으면(null) 비공개
IconData visibilityLevelIcon(VisibilityLevel? level) => switch (level) {
  VisibilityLevel.friends => Icons.group_outlined,
  VisibilityLevel.selected => Icons.how_to_reg_outlined,
  VisibilityLevel.allowedEmails => Icons.alternate_email,
  VisibilityLevel.public => Icons.public,
  _ => Icons.lock_outline,
};

/// 지금 공유 범위 [level]을 아이콘으로 보이는 버튼. 누르면 [onPressed]로 공유 설정을 연다
class VisibilityButton extends StatelessWidget {
  const VisibilityButton({
    super.key,
    required this.level,
    required this.onPressed,
  });

  final VisibilityLevel? level;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(visibilityLevelIcon(level)),
      tooltip: Terms.visibility,
      onPressed: onPressed,
    );
  }
}
