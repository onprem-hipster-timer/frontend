// 사용성 분석(Microsoft Clarity)에 보내는 이벤트와 세션 태그
//
// 이름과 값은 아래 enum의 고정 문자열뿐이다. 사람이 넣은 글자(닉네임 등)나 식별자(id·handle·모임 번호·제목)는
// 보내지 않는다. 웹에서는 Clarity가 불러와져 있을 때(사용성 분석에 동의했을 때, web/landing/analytics.js)만
// `window.clarity`로 보내고, 그 밖(동의 전, 웹이 아님, 테스트)에는 아무것도 하지 않는다. Clarity를 불러오거나
// 미리 쌓아 두지 않는다.
//
// 이름 목록과 Clarity에서 보는 법: docs/analytics.md

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:momeet/core/analytics/usage_analytics_stub.dart'
    if (dart.library.js_interop) 'package:momeet/core/analytics/usage_analytics_web.dart';

/// 보내는 이벤트(`clarity("event", id)`)
enum UsageEvent {
  /// 방문자에게 로그인·Guest 요청을 띄웠다(좁으면 요청 시트, 넓으면 칠하려 해서 옆의 로그인 상자를 떨었다)
  meetingLoginRequestShown('meeting_login_request_shown'),

  /// 방문자가 요청에서 '로그인'을 골랐다
  meetingLoginChosen('meeting_login_chosen'),

  /// 방문자가 요청에서 'Guest'를 골랐다
  meetingGuestChosen('meeting_guest_chosen'),

  /// 로그인한 회원이 모임 화면을 열었다(모임 화면 하나에 한 번)
  meetingMemberArrived('meeting_member_arrived'),

  /// 처음 쓰는 이름으로 게스트가 되어 들어갔다
  meetingGuestEnteredNew('meeting_guest_entered_new'),

  /// 이미 있는 게스트 이름으로 들어갔다
  meetingGuestEnteredReturning('meeting_guest_entered_returning'),

  /// 게스트로 넣은 시간을 회원 계정으로 옮겼다
  meetingGuestConverted('meeting_guest_converted');

  const UsageEvent(this.id);

  final String id;
}

/// 세션 태그(`clarity("set", key, value)`)
abstract interface class UsageTag {
  String get key;
  String get value;
}

/// 모임 화면을 보는 계정 종류. 한 세션에서 바뀌면(방문자 → 게스트) 값이 더해진다
enum MeetingAccountTag implements UsageTag {
  visitor,
  member,
  guest;

  @override
  String get key => 'meeting_account';

  @override
  String get value => name;
}

/// 사용성 분석에 보내는 곳
abstract interface class UsageAnalytics {
  void event(UsageEvent event);
  void tag(UsageTag tag);
}

/// 실행 환경의 [UsageAnalytics]. 테스트에서 덮어쓴다
final usageAnalyticsProvider = Provider<UsageAnalytics>(
  (ref) => createUsageAnalytics(),
);
