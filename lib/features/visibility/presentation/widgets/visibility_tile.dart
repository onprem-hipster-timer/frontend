import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/visibility/presentation/widgets/visibility_button.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 지금 공유 범위 [level]을 아이콘과 이름으로 보이는 줄. 누르면 [onTap]으로 공유 설정을 연다
class VisibilityTile extends StatelessWidget {
  const VisibilityTile({super.key, required this.level, required this.onTap});

  final VisibilityLevel? level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(visibilityLevelIcon(level)),
      title: const Text(Terms.visibility),
      subtitle: Text(visibilityLevelLabel(level)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
