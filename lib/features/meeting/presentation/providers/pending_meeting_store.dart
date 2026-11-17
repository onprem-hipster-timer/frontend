import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/shared_preferences_provider.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그인하러 가며 둔 모임 만들기 폼: 값과 제목 칸의 글자
typedef PendingMeeting = ({MeetingDraft draft, String title});

/// 로그인하지 않은 사람이 모임을 만들려다 로그인하러 가는 동안 폼을 이 기기에 둔다. 로그인을 다녀오는 사이
/// 앱이 새로 뜰 수 있어서다(Google 로그인). 만들기 화면이 열릴 때 한 번 꺼내고 지운다.
///
/// 테스트: test/features/meeting/presentation/providers/pending_meeting_store_test.dart
class PendingMeetingStore {
  PendingMeetingStore(this._prefs);

  static const key = 'momeet.pending_meeting';

  final SharedPreferences _prefs;

  Future<void> save(PendingMeeting pending) {
    final draft = pending.draft;
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
        'title': pending.title,
      }),
    );
  }

  /// 둔 폼을 꺼내고 지운다. 없거나, 읽을 수 없거나, 첫날이 [today]보다 앞이면 null
  PendingMeeting? take({required DateTime today}) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    unawaited(_prefs.remove(key));
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      final dates = MeetingDates.of([
        for (final day in json['days']! as List) DateTime.parse(day as String),
      ]);
      if (!dates.isEmpty && dates.first.isBefore(calendarDay(today))) {
        return null;
      }
      return (
        draft: MeetingDraft(
          mode: MeetingMode.values.byName(json['mode']! as String),
          dates: dates,
          startHour: json['start_hour']! as int,
          endHour: json['end_hour']! as int,
          isPublic: json['public']! as bool,
          allowGuests: json['guests']! as bool,
        ),
        title: json['title']! as String,
      );
    } on Object {
      return null;
    }
  }
}

final pendingMeetingStoreProvider = Provider<PendingMeetingStore>(
  (ref) => PendingMeetingStore(ref.watch(sharedPreferencesProvider)),
);
