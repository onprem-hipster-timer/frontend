import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

/// 견본 값으로 덮어쓴 프로바이더만 읽게 하는 [ProviderScope]. use case의 위젯 트리가 읽는 프로바이더를 모두
/// [overrides]로 덮어쓴다. 덮어쓰지 않은 프로바이더를 읽으면 앱의 진짜 프로바이더가 도는 대신 오류가 난다.
class SampleProviderScope extends StatelessWidget {
  const SampleProviderScope({
    super.key,
    required this.overrides,
    required this.child,
  });

  final List<Override> overrides;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      observers: [_OnlyOverridden(overrides)],
      child: Builder(
        builder: (context) => _CapturedScope(
          container: ProviderScope.containerOf(context, listen: false),
          child: child,
        ),
      ),
    );
  }
}

/// 시트·다이얼로그·메뉴는 use case 바깥의 Navigator에 놓이므로, 띄울 때 함께 옮겨지는 테마([InheritedTheme])로
/// 같은 견본 Provider를 그 안까지 잇는다
class _CapturedScope extends InheritedTheme {
  const _CapturedScope({required this.container, required super.child});

  final ProviderContainer container;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      UncontrolledProviderScope(container: container, child: child);

  @override
  bool updateShouldNotify(_CapturedScope oldWidget) =>
      container != oldWidget.container;
}

final class _OnlyOverridden extends ProviderObserver {
  _OnlyOverridden(List<Override> overrides)
    // Override는 덮어쓴 프로바이더(origin)를 테스트용으로만 내보이므로 동적으로 읽는다
    : _overridden = {
        for (final override in overrides) (override as dynamic).origin,
      };

  final Set<Object?> _overridden;

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    final provider = context.provider;
    if (_overridden.contains(provider) || _overridden.contains(provider.from)) {
      return;
    }
    throw StateError('견본 값으로 덮어쓰지 않은 프로바이더를 읽었습니다: $provider');
  }
}
