// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

/// Deferred import 라이브러리를 로드한 뒤 위젯을 빌드하는 헬퍼
///
/// [loader]로 `loadLibrary()`를 받아 비동기 로딩을 처리하고,
/// 로딩 완료 후 [builder]로 실제 위젯을 생성합니다.
///
/// 사용 예:
/// ```dart
/// import 'package:app/feature.dart' deferred as feature;
///
/// DeferredWidget(
///   loader: feature.loadLibrary,
///   builder: (_) => feature.FeaturePage(),
/// )
/// ```
class DeferredWidget extends StatefulWidget {
  const DeferredWidget({
    required this.loader,
    required this.builder,
    super.key,
  });

  /// deferred library의 `loadLibrary` 함수
  final Future<void> Function() loader;

  /// 라이브러리 로드 완료 후 위젯 빌더
  final WidgetBuilder builder;

  @override
  State<DeferredWidget> createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  late final Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '페이지를 불러올 수 없습니다',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return widget.builder(context);
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
