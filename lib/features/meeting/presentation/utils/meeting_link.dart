import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/share/system_share.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 [meetingId]의 공유 링크 (웹 앱 주소 + 모임 화면 경로)
Uri meetingLink(BuildContext context, WidgetRef ref, String meetingId) =>
    Uri.parse(ref.read(appOriginProvider)).replace(
      path: context.namedLocation(
        AppRoute.meeting.name,
        pathParameters: {'meetingId': meetingId},
      ),
    );

/// 모임 [meetingId]의 공유 링크를 복사하고 알린다
Future<void> copyMeetingLink(
  BuildContext context,
  WidgetRef ref,
  String meetingId,
) async {
  await Clipboard.setData(
    ClipboardData(text: '${meetingLink(context, ref, meetingId)}'),
  );
  if (context.mounted) {
    showAppSnackBar(context, '링크를 복사했습니다', kind: AppNoticeKind.success);
  }
}

/// '공유하기': 시스템 공유 창이 있으면 모임 제목 [title]과 링크로 열고, 없거나 공유하지 못하면 링크를 복사하고
/// 알린다([copyMeetingLink]). 공유 창을 닫으면 아무것도 하지 않는다
Future<void> shareMeetingLink(
  BuildContext context,
  WidgetRef ref, {
  required String meetingId,
  required String title,
}) async {
  final result = await ref.read(systemShareProvider)(
    title: title,
    url: '${meetingLink(context, ref, meetingId)}',
  );
  if (!context.mounted) return;
  switch (result) {
    case SystemShareResult.shared || SystemShareResult.dismissed:
      return;
    case SystemShareResult.unavailable || SystemShareResult.failed:
      await copyMeetingLink(context, ref, meetingId);
  }
}

/// 모임 [meetingId]의 설정 화면을 연다(주인만)
void openMeetingEdit(BuildContext context, String meetingId) =>
    context.pushNamed(
      AppRoute.meetingEdit.name,
      pathParameters: {'meetingId': meetingId},
    );

/// 로그인 화면으로 간다. 로그인하면 모임 [meetingId] 화면으로 돌아온다
void goToLoginForMeeting(BuildContext context, String meetingId) =>
    context.goNamed(
      AppRoute.login.name,
      queryParameters: {
        'redirect': context.namedLocation(
          AppRoute.meeting.name,
          pathParameters: {'meetingId': meetingId},
        ),
      },
    );
