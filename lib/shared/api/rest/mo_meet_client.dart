// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'schedules/schedules_client.dart';
import 'timers/timers_client.dart';
import 'holidays/holidays_client.dart';
import 'tags/tags_client.dart';
import 'todos/todos_client.dart';
import 'friends/friends_client.dart';
import 'graph_ql/graph_ql_client.dart';
import 'health/health_client.dart';

/// onperm-hipster-timer-backend `v1.0.0`
class MoMeetClient {
  MoMeetClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  SchedulesClient? _schedules;
  TimersClient? _timers;
  HolidaysClient? _holidays;
  TagsClient? _tags;
  TodosClient? _todos;
  FriendsClient? _friends;
  GraphQlClient? _graphQl;
  HealthClient? _health;

  SchedulesClient get schedules =>
      _schedules ??= SchedulesClient(_dio, baseUrl: _baseUrl);

  TimersClient get timers => _timers ??= TimersClient(_dio, baseUrl: _baseUrl);

  HolidaysClient get holidays =>
      _holidays ??= HolidaysClient(_dio, baseUrl: _baseUrl);

  TagsClient get tags => _tags ??= TagsClient(_dio, baseUrl: _baseUrl);

  TodosClient get todos => _todos ??= TodosClient(_dio, baseUrl: _baseUrl);

  FriendsClient get friends =>
      _friends ??= FriendsClient(_dio, baseUrl: _baseUrl);

  GraphQlClient get graphQl =>
      _graphQl ??= GraphQlClient(_dio, baseUrl: _baseUrl);

  HealthClient get health => _health ??= HealthClient(_dio, baseUrl: _baseUrl);
}
