// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timers_client.dart';

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main

class _TimersClient implements TimersClient {
  _TimersClient(this._dio, {this.baseUrl, this.errorLogger});

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<List<TimerRead>> listTimersV1TimersGet({
    List<String>? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? timezone,
    ResourceScope? scope = ResourceScope.mine,
    bool? includeSchedule = false,
    bool? includeTodo = false,
    TagIncludeMode? tagIncludeMode = TagIncludeMode.none,
    RequestOptions? options,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'status': status,
      r'type': type,
      r'start_date': startDate?.toIso8601String(),
      r'end_date': endDate?.toIso8601String(),
      r'timezone': timezone,
      r'scope': scope,
      r'include_schedule': includeSchedule,
      r'include_todo': includeTodo,
      r'tag_include_mode': tagIncludeMode,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final newOptions = newRequestOptions(options);
    newOptions.extra.addAll(_extra);
    newOptions.headers.addAll(_dio.options.headers);
    newOptions.headers.addAll(_headers);
    final _options = newOptions.copyWith(
      method: 'GET',
      baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
      queryParameters: queryParameters,
      path: '/v1/timers',
    )..data = _data;
    final _result = await _dio.fetch<List<dynamic>>(_options);
    late List<TimerRead> _value;
    try {
      _value = _result.data!
          .map((dynamic i) => TimerRead.fromJson(i as Map<String, dynamic>))
          .toList();
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<TimerRead> getUserActiveTimerV1TimersActiveGet({
    String? timezone,
    bool? includeSchedule = false,
    bool? includeTodo = false,
    TagIncludeMode? tagIncludeMode = TagIncludeMode.none,
    RequestOptions? options,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'timezone': timezone,
      r'include_schedule': includeSchedule,
      r'include_todo': includeTodo,
      r'tag_include_mode': tagIncludeMode,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final newOptions = newRequestOptions(options);
    newOptions.extra.addAll(_extra);
    newOptions.headers.addAll(_dio.options.headers);
    newOptions.headers.addAll(_headers);
    final _options = newOptions.copyWith(
      method: 'GET',
      baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
      queryParameters: queryParameters,
      path: '/v1/timers/active',
    )..data = _data;
    final _result = await _dio.fetch<Map<String, Object?>>(_options);
    late TimerRead _value;
    try {
      _value = TimerRead.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<TimerRead> getTimerV1TimersTimerIdGet({
    required String timerId,
    String? timezone,
    bool? includeSchedule = false,
    bool? includeTodo = false,
    TagIncludeMode? tagIncludeMode = TagIncludeMode.none,
    RequestOptions? options,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'timezone': timezone,
      r'include_schedule': includeSchedule,
      r'include_todo': includeTodo,
      r'tag_include_mode': tagIncludeMode,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final newOptions = newRequestOptions(options);
    newOptions.extra.addAll(_extra);
    newOptions.headers.addAll(_dio.options.headers);
    newOptions.headers.addAll(_headers);
    final _options = newOptions.copyWith(
      method: 'GET',
      baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
      queryParameters: queryParameters,
      path: '/v1/timers/${timerId}',
    )..data = _data;
    final _result = await _dio.fetch<Map<String, Object?>>(_options);
    late TimerRead _value;
    try {
      _value = TimerRead.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<TimerRead> updateTimerV1TimersTimerIdPatch({
    required String timerId,
    required TimerUpdate body,
    String? timezone,
    bool? includeSchedule = false,
    bool? includeTodo = false,
    TagIncludeMode? tagIncludeMode = TagIncludeMode.none,
    RequestOptions? options,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'timezone': timezone,
      r'include_schedule': includeSchedule,
      r'include_todo': includeTodo,
      r'tag_include_mode': tagIncludeMode,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    final _data = body;
    final newOptions = newRequestOptions(options);
    newOptions.extra.addAll(_extra);
    newOptions.headers.addAll(_dio.options.headers);
    newOptions.headers.addAll(_headers);
    final _options = newOptions.copyWith(
      method: 'PATCH',
      baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
      queryParameters: queryParameters,
      path: '/v1/timers/${timerId}',
    )..data = _data;
    final _result = await _dio.fetch<Map<String, Object?>>(_options);
    late TimerRead _value;
    try {
      _value = TimerRead.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<void> deleteTimerV1TimersTimerIdDelete({
    required String timerId,
    RequestOptions? options,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final newOptions = newRequestOptions(options);
    newOptions.extra.addAll(_extra);
    newOptions.headers.addAll(_dio.options.headers);
    newOptions.headers.addAll(_headers);
    final _options = newOptions.copyWith(
      method: 'DELETE',
      baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
      queryParameters: queryParameters,
      path: '/v1/timers/${timerId}',
    )..data = _data;
    await _dio.fetch<void>(_options);
  }

  RequestOptions newRequestOptions(Object? options) {
    if (options is RequestOptions) {
      return options;
    }
    if (options is Options) {
      return RequestOptions(
        method: options.method,
        sendTimeout: options.sendTimeout,
        receiveTimeout: options.receiveTimeout,
        extra: options.extra,
        headers: options.headers,
        responseType: options.responseType,
        contentType: options.contentType.toString(),
        validateStatus: options.validateStatus,
        receiveDataWhenStatusError: options.receiveDataWhenStatusError,
        followRedirects: options.followRedirects,
        maxRedirects: options.maxRedirects,
        requestEncoder: options.requestEncoder,
        responseDecoder: options.responseDecoder,
        path: '',
      );
    }
    return RequestOptions(path: '');
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(String dioBaseUrl, String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}

// dart format on
