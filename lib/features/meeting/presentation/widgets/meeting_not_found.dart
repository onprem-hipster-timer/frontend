import 'package:dio/dio.dart' show DioException;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임을 받지 못한 까닭이 없는 모임인지(404). backend는 볼 수 없는 모임도 없는 모임과 똑같이 404로 답한다
bool isMeetingNotFound(Object error) =>
    error is DioException && error.response?.statusCode == 404;

/// '모임을 찾을 수 없습니다'. 없는 모임과 볼 수 없는 모임을 가리지 않는다.
///
/// [onLogin]을 주면(로그인하지 않았을 때) 로그인하면 볼 수 있는 모임일 수 있다고 적고 '로그인'을 둔다.
class MeetingNotFound extends StatelessWidget {
  const MeetingNotFound({super.key, this.onLogin});

  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.event_busy_outlined,
      title: '${Terms.meeting.withJosa('을', '를')} 찾을 수 없습니다',
      message: onLogin == null
          ? '링크가 맞는지 확인해 주세요.'
          : '링크가 맞는지 확인해 주세요. 로그인하면 볼 수 있는 ${Terms.meeting}일 수도 있습니다.',
      actionLabel: onLogin == null ? null : '로그인',
      actionIcon: Icons.login,
      onAction: onLogin,
    );
  }
}
