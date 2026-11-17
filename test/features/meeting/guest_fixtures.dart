import 'dart:async';

import 'package:dio/dio.dart' show RequestOptions;
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/network/turnstile_request.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../helpers/fake_rest_clients.dart';

/// 게스트 경로가 [statusCode]와 [errorType]으로 거절한 요청의 오류 (backend 공통 오류 형식)
Object guestError(int statusCode, String errorType, {int? retryAfter}) =>
    httpError(
      '/v1/guests',
      statusCode,
      data: {
        'error_type': errorType,
        'message': errorType,
        'retry_after': ?retryAfter,
      },
    );

/// 이 모임의 게스트를 들고 있는 [GuestsClient]. 받은 요청과 그 Turnstile 토큰을 기록한다
class FakeGuestsClient extends Fake implements GuestsClient {
  /// 이 모임의 게스트: 이름 → handle
  final guests = <String, String>{};

  /// 지금 약관 버전
  var consentVersion = '2026-11-13';

  /// 받은 이름 찾기 (이름, 토큰)
  final lookups = <(String, String?)>[];

  /// 받은 생성 (본문, 토큰)
  final creates = <(GuestCreate, String?)>[];

  /// 받은 자기 삭제의 토큰
  final deletes = <String?>[];

  /// 받은 약관 동의 (토큰이 없어야 한다)
  final consents = <(ConsentCreate, String?)>[];

  /// 다음 요청 하나가 이 오류로 실패한다
  Object? lookupError;
  Object? createError;
  Object? deleteError;
  Object? consentError;

  /// 설정하면 이름 찾기가 이것이 끝날 때까지 기다린다
  Completer<void>? lookupGate;

  /// 설정하면 자기 삭제가 이것이 끝날 때까지 기다린다
  Completer<void>? deleteGate;

  static String? _token(RequestOptions? options) =>
      options?.headers[turnstileTokenHeader] as String?;

  Object? _take(Object? Function() read, void Function() clear) {
    final error = read();
    clear();
    return error;
  }

  @override
  Future<GuestLookupRead> lookupGuestV1GuestsLookupPost({
    required GuestLookup body,
    RequestOptions? options,
  }) async {
    lookups.add((body.name, _token(options)));
    final gate = lookupGate;
    if (gate != null) await gate.future;
    if (_take(() => lookupError, () => lookupError = null) case final e?) {
      throw e;
    }
    return GuestLookupRead(
      handle: guests[body.name],
      consentVersion: consentVersion,
    );
  }

  @override
  Future<GuestRead> createGuestV1GuestsPost({
    required GuestCreate body,
    RequestOptions? options,
  }) async {
    creates.add((body, _token(options)));
    if (_take(() => createError, () => createError = null) case final e?) {
      throw e;
    }
    if (body.consent.version != consentVersion) {
      throw guestError(409, 'ConsentVersionMismatchError');
    }
    if (guests.containsKey(body.name)) {
      throw guestError(409, 'GuestNameTakenError');
    }
    final id = 'g${guests.length + 1}';
    final handle = guests[body.name] = '$id@guest.invalid';
    return GuestRead(
      guestId: id,
      handle: handle,
      resourceType: body.resourceType,
      resourceId: body.resourceId,
    );
  }

  @override
  Future<void> deleteMeV1GuestsMeDelete({RequestOptions? options}) async {
    deletes.add(_token(options));
    await deleteGate?.future;
    if (_take(() => deleteError, () => deleteError = null) case final e?) {
      throw e;
    }
  }

  @override
  Future<void> putMyConsentV1GuestsMeConsentPut({
    required ConsentCreate body,
    RequestOptions? options,
  }) async {
    consents.add((body, _token(options)));
    if (_take(() => consentError, () => consentError = null) case final e?) {
      throw e;
    }
  }
}
