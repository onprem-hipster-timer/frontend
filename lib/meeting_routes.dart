// 모임 만들기·만든 뒤·설정·모임 화면의 라우트. 탭 셸 밖의 독립 화면이다(Floating Navigation 없음)

import 'package:go_router/go_router.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/features/meeting/meeting.dart' deferred as meeting;
import 'package:momeet/shared/widgets/deferred_widget.dart';

/// 만든 뒤 화면은 만들기 화면 위에 쌓지 않고 바꾼다. 모임 화면은 공유 링크로 연다. 설정 화면은 모임 화면 위에 쌓는다
final meetingRoutes = <RouteBase>[
  GoRoute(
    path: AppRoute.meetings.path,
    name: AppRoute.meetings.name,
    builder: (context, state) => DeferredWidget(
      loader: meeting.loadLibrary,
      builder: (_) => meeting.MeetingCreatePage(),
    ),
  ),
  GoRoute(
    path: AppRoute.meetingCreated.path,
    name: AppRoute.meetingCreated.name,
    builder: (context, state) => DeferredWidget(
      loader: meeting.loadLibrary,
      builder: (_) => meeting.MeetingCreatedPage(
        meetingId: state.pathParameters['meetingId']!,
      ),
    ),
  ),
  GoRoute(
    path: AppRoute.meetingEdit.path,
    name: AppRoute.meetingEdit.name,
    builder: (context, state) => DeferredWidget(
      loader: meeting.loadLibrary,
      builder: (_) => meeting.MeetingEditPage(
        meetingId: state.pathParameters['meetingId']!,
      ),
    ),
  ),
  GoRoute(
    path: AppRoute.meeting.path,
    name: AppRoute.meeting.name,
    builder: (context, state) => DeferredWidget(
      loader: meeting.loadLibrary,
      builder: (_) =>
          meeting.MeetingPage(meetingId: state.pathParameters['meetingId']!),
    ),
  ),
];
