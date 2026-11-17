import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

/// 모임 화면의 유리 머리띠([MeetingGlassScaffold]가 쓴다). [under]면 뒤의 본문을 흐리게 비추고 바탕색을 옅게 깐다.
/// 바탕색의 진하기는 글자와 아이콘이 가장 진한 칸(강조색) 위에서도 WCAG AA를 넘게 정했다
class MeetingGlassBar extends StatelessWidget implements PreferredSizeWidget {
  const MeetingGlassBar({
    super.key,
    required this.title,
    required this.leading,
    required this.under,
  });

  final Widget title;
  final Widget? leading;
  final bool under;

  /// 글자와 아이콘이 가장 진한 칸(강조색) 위에서도 읽히게 까는 바탕색의 진하기
  static const _tint = 0.75;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clear = scheme.surface.withValues(alpha: 0);
    return AppBar(
      leading: leading,
      title: title,
      backgroundColor: clear,
      surfaceTintColor: clear,
      shadowColor: clear,
      elevation: 0,
      scrolledUnderElevation: 0,
      notificationPredicate: (_) => false,
      flexibleSpace: TweenAnimationBuilder<double>(
        tween: Tween(end: under ? 1 : 0),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        builder: (context, t, _) {
          final glass = DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: _tint * t),
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: t),
                  width: 0.5,
                ),
              ),
            ),
            child: const SizedBox.expand(),
          );
          if (t == 0) return glass;
          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16 * t, sigmaY: 16 * t),
              child: glass,
            ),
          );
        },
      ),
    );
  }
}
