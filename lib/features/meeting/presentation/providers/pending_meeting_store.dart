import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/shared_preferences_provider.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_title_field.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그인하러 가며 둔 모임 만들기 폼: 값·답한 질문(펼친 폼이면 펼친 폼)과 제목 칸의 글자
typedef PendingMeeting = ({MeetingFlow flow, String title});

/// 로그인하지 않은 사람이 모임을 만들려다 로그인하러 가는 동안 폼을 이 기기에 둔다. 로그인을 다녀오는 사이
/// 앱이 새로 뜰 수 있어서다(Google 로그인). 만들기 화면이 열릴 때 한 번 꺼내고 지운다.
///
/// 테스트: test/features/meeting/presentation/providers/pending_meeting_store_test.dart
class PendingMeetingStore {
  PendingMeetingStore(this._prefs);

  static const key = 'momeet.pending_meeting';

  final SharedPreferences _prefs;

  /// 폼을 둔다. 펼친 폼이 아니면 답한 질문을 함께 둔다(기간을 고르던 중인 시작일은 두지 않는다)
  Future<void> save(PendingMeeting pending) {
    final flow = pending.flow;
    final draft = flow.draft;
    return _prefs.setString(
      key,
      jsonEncode({
        'mode': draft.mode.name,
        'days': [
          for (final day in draft.dates.days)
            day.toIso8601String().substring(0, 10),
        ],
        'start_hour': draft.startHour,
        'end_hour': draft.endHour,
        'public': draft.isPublic,
        'guests': draft.allowGuests,
        'emails': draft.emails,
        'domains': draft.domains,
        'only_me': draft.onlyMe,
        if (!flow.expanded)
          'answered': [for (final question in flow.answered) question.name],
        'title': pending.title,
      }),
    );
  }

  /// 둔 폼을 꺼내고 지운다. 폼의 규칙으로 다시 만들고([MeetingDraft.restore], 비공개에 넣은 이메일·도메인도
  /// 다시 읽는다) 제목은 제목 칸처럼 자른다.
  /// 답한 질문이 없으면(펼친 폼, 이전 형식) 펼친 폼이고, 모르는 질문 이름은 버린다.
  /// 없거나, 읽을 수 없거나, 폼이 만들 수 없는 값이면 null
  PendingMeeting? take({required DateTime today}) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    unawaited(_prefs.remove(key));
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      final draft = MeetingDraft.restore(
        mode: MeetingMode.values.byName(json['mode']! as String),
        days: [
          for (final day in json['days']! as List)
            DateTime.parse(day as String),
        ],
        startHour: json['start_hour']! as int,
        endHour: json['end_hour']! as int,
        isPublic: json['public']! as bool,
        allowGuests: json['guests']! as bool,
        today: today,
        access: [
          for (final key in ['emails', 'domains'])
            for (final entry in (json[key] as List?) ?? const [])
              entry as String,
        ],
        onlyMe: json['only_me'] as bool? ?? false,
      );
      if (draft == null) return null;
      final answered = json['answered'] as List?;
      final title =
          LengthLimitingTextInputFormatter(MeetingTitleField.maxLength)
              .formatEditUpdate(
                TextEditingValue.empty,
                TextEditingValue(text: json['title']! as String),
              )
              .text;
      return (
        flow: MeetingFlow.restored(
          draft,
          answered: answered == null
              ? null
              : {
                  for (final name in answered)
                    ?MeetingQuestion.values.asNameMap()[name],
                },
        ),
        title: title,
      );
    } on Object {
      return null;
    }
  }
}

final pendingMeetingStoreProvider = Provider<PendingMeetingStore>(
  (ref) => PendingMeetingStore(ref.watch(sharedPreferencesProvider)),
);
