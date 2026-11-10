// 본인 프로필(GET /v1/users/me)과 약관 동의

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

part 'my_profile_provider.g.dart';

/// 로그인한 사용자의 프로필. 로그인하지 않았으면 null
@Riverpod(keepAlive: true)
class MyProfileNotifier extends _$MyProfileNotifier {
  @override
  Future<MyProfileRead?> build() async {
    // JWT를 새로 받을 때마다 다시 부르지 않도록 사용자가 바뀔 때만 다시 받는다
    final userId = ref.watch(currentUserProvider.select((user) => user?.id));
    if (userId == null) return null;
    return ref.read(usersApiProvider).getMyProfileV1UsersMeGet();
  }

  /// 만 14세 이상·이용약관·개인정보 수집·이용에 동의한다.
  ///
  /// [version]은 프로필이 알려 준 현재 약관 버전이다. 그 사이 약관이 바뀌었으면
  /// 서버가 409로 거절하고, 그 오류를 그대로 던진다.
  Future<void> agree(String version) async {
    final profile = await ref
        .read(usersApiProvider)
        .putMyConsentV1UsersMeConsentPut(
          body: ConsentCreate(
            version: version,
            ageOver14: true,
            terms: true,
            privacy: true,
          ),
        );
    state = AsyncData(profile);
  }
}

/// 로그인한 사용자가 약관에 동의해야 하는지. 프로필을 불러오는 중이거나 실패했으면 null
@riverpod
bool? consentRequired(Ref ref) {
  final profile = ref.watch(myProfileProvider);
  if (profile.isLoading || profile.hasError) return null;
  return profile.value?.consentRequired;
}
