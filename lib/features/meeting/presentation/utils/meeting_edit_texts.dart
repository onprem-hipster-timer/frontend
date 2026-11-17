import 'package:dio/dio.dart' show DioException;
import 'package:momeet/features/meeting/domain/meeting_edit.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_edit_providers.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 모임 설정 화면의 문구

const meetingEditTitle = '${Terms.meeting} 설정';
const meetingEditTitleLabel = '제목';
const meetingEditSave = '저장하기';
const meetingEditSaved = '${Terms.meeting} 설정을 저장했어요';
const meetingEditAccessRequired = "이메일을 하나 이상 넣거나 '지금은 나만 볼게요'를 골라야 저장할 수 있어요";
const meetingEditLoadFailed = '${Terms.meeting} 설정을 불러오지 못했습니다';

const meetingDelete = '${Terms.meeting} 삭제';
const meetingDeleteConfirm = '삭제하기';
final meetingDeleteQuestion =
    '참여자가 넣은 답과 게스트가 모두 지워져요. '
    '지운 ${Terms.meeting.withJosa('은', '는')} 되돌릴 수 없어요.';
final meetingDeleted = '${Terms.meeting.withJosa('을', '를')} 삭제했어요';
final meetingDeleteFailed =
    '${Terms.meeting.withJosa('을', '를')} 삭제하지 못했어요. 잠시 뒤 다시 시도해 주세요';

/// 참여자가 이미 답을 넣었을 때 저장 전에 보이는 한 줄
String meetingEditNoticeText(MeetingEditNotice notice) => switch (notice) {
  MeetingEditNotice.modeChanged => '이미 넣은 답이 다르게 보일 수 있어요. 답은 지워지지 않아요',
  MeetingEditNotice.daysDropped => '빠진 날에 넣은 답은 보이지 않아요. 답은 지워지지 않아요',
};

/// 저장 결과를 알릴 때 쓰는 이름
String meetingEditPartName(MeetingEditPart part) => switch (part) {
  MeetingEditPart.title => '제목',
  MeetingEditPart.dates => '날짜',
  MeetingEditPart.mode => '받는 방식',
  MeetingEditPart.time => '시간',
  MeetingEditPart.visibility => '공개 범위',
  MeetingEditPart.guests => '게스트 로그인',
};

/// 서버가 거절한 칸 옆에 보이는 말
String meetingEditRefusalText(MeetingEditPart part) => switch (part) {
  MeetingEditPart.title => '이 제목으로는 바꿀 수 없어요',
  MeetingEditPart.dates => '이 날짜로는 바꿀 수 없어요. 기간과 제외한 날을 확인해 주세요',
  MeetingEditPart.mode => '이 날짜에서는 이 방식으로 바꿀 수 없어요',
  MeetingEditPart.time => '이 시간 범위로는 바꿀 수 없어요',
  MeetingEditPart.visibility => '이 공개 범위로는 바꿀 수 없어요. 넣은 이메일과 도메인을 확인해 주세요',
  MeetingEditPart.guests => '지금은 게스트 로그인을 바꿀 수 없어요',
};

/// 검사 오류의 칸 이름이 가리키는 고치는 것
const _partOfField = {
  'title': MeetingEditPart.title,
  'start_date': MeetingEditPart.dates,
  'end_date': MeetingEditPart.dates,
  'excluded_dates': MeetingEditPart.dates,
  'mode': MeetingEditPart.mode,
  'start_time': MeetingEditPart.time,
  'end_time': MeetingEditPart.time,
  'time_slot_minutes': MeetingEditPart.time,
  'allow_guests': MeetingEditPart.guests,
  'level': MeetingEditPart.visibility,
  'allowed_emails': MeetingEditPart.visibility,
  'allowed_domains': MeetingEditPart.visibility,
  'allowed_user_ids': MeetingEditPart.visibility,
};

/// 저장하지 못한 [outcome]에서 서버가 거절한(422) 칸. `detail` 목록의 칸 이름(`loc`·`field`, 또는 이름 글자)으로
/// 고르고, 이름이 없거나 모르는 이름이면 거절된 요청이 하나만 저장하려던 때 그것이다
Set<MeetingEditPart> meetingEditRefused(MeetingEditOutcome outcome) {
  final error = outcome.error;
  if (error is! DioException || error.response?.statusCode != 422) return {};
  final data = error.response?.data;
  final detail = data is Map ? data['detail'] : null;
  final named = <MeetingEditPart>{
    if (detail is List)
      for (final item in detail)
        for (final name in switch (item) {
          {'loc': final List<Object?> loc} => loc,
          {'field': final Object? field} => [field],
          final String field => [field],
          _ => const <Object?>[],
        })
          ?_partOfField[name],
  }.intersection(outcome.unsaved);
  if (named.isNotEmpty) return named;
  return outcome.unsaved.length == 1 ? outcome.unsaved : {};
}

/// 저장하지 못한 [outcome]을 알리는 말. 저장한 것과 저장하지 못한 것을 나눠 적고 까닭을 붙인다
String meetingEditOutcomeText(MeetingEditOutcome outcome) {
  String names(Set<MeetingEditPart> parts) {
    final text = [
      for (final part in MeetingEditPart.values)
        if (parts.contains(part)) meetingEditPartName(part),
    ].join('·');
    return text.withJosa('은', '는');
  }

  final reason = switch (outcome.error) {
    DioException(response: null) => '네트워크 연결을 확인해 주세요',
    DioException(response: final response?) when response.statusCode == 422 =>
      meetingEditRefused(outcome).isEmpty ? '바꿀 수 없는 값이 있어요' : '표시한 칸을 확인해 주세요',
    _ => '잠시 뒤 다시 시도해 주세요',
  };
  final unsaved = '${names(outcome.unsaved)} 저장하지 못했어요. $reason';
  return outcome.saved.isEmpty
      ? '저장하지 못했어요. $reason'
      : '${names(outcome.saved)} 저장했어요. $unsaved';
}
