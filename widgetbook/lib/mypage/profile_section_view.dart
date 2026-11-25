import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError, AsyncLoading, AsyncValue;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/mypage/domain/my_page_models.dart';
import 'package:momeet/features/mypage/presentation/widgets/profile_section_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

enum _Load { done, signedOut, loading, failed }

@widgetbook.UseCase(name: '프로필 카드', type: ProfileSectionView, path: '[마이페이지]')
Widget profileSectionView(BuildContext context) {
  final knobs = context.knobs;
  final load = knobs.object.dropdown(
    label: '상태',
    options: _Load.values,
    labelBuilder: (load) => switch (load) {
      _Load.done => '불러옴',
      _Load.signedOut => '사용자 정보 없음',
      _Load.loading => '불러오는 중',
      _Load.failed => '불러올 수 없음',
    },
  );
  final email = knobs.string(
    label: '이메일',
    initialValue: 'haneul.kim@example.com',
  );
  final AsyncValue<UserProfile?> profile = switch (load) {
    _Load.done => AsyncData(
      UserProfile(email: email, createdAt: DateTime(2025, 3, 2)),
    ),
    _Load.signedOut => const AsyncData(null),
    _Load.loading => const AsyncLoading(),
    _Load.failed => AsyncError(Exception('불러오기 실패'), StackTrace.empty),
  };
  // 앱에서는 마이페이지 맨 위, 좌우 20 여백 안에 놓인다
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: ProfileSectionView(profile: profile, onRetry: () {}),
  );
}
