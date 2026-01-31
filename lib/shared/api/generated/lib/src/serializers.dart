//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:openapi_client/src/date_serializer.dart';
import 'package:openapi_client/src/model/date.dart';

import 'package:openapi_client/src/model/create_todo_options.dart';
import 'package:openapi_client/src/model/friend_read.dart';
import 'package:openapi_client/src/model/friend_request.dart';
import 'package:openapi_client/src/model/friendship_read.dart';
import 'package:openapi_client/src/model/friendship_status.dart';
import 'package:openapi_client/src/model/http_validation_error.dart';
import 'package:openapi_client/src/model/holiday_item.dart';
import 'package:openapi_client/src/model/pending_request_read.dart';
import 'package:openapi_client/src/model/resource_scope.dart';
import 'package:openapi_client/src/model/schedule_create.dart';
import 'package:openapi_client/src/model/schedule_read.dart';
import 'package:openapi_client/src/model/schedule_state.dart';
import 'package:openapi_client/src/model/schedule_update.dart';
import 'package:openapi_client/src/model/tag_create.dart';
import 'package:openapi_client/src/model/tag_group_create.dart';
import 'package:openapi_client/src/model/tag_group_read.dart';
import 'package:openapi_client/src/model/tag_group_read_with_tags.dart';
import 'package:openapi_client/src/model/tag_group_update.dart';
import 'package:openapi_client/src/model/tag_include_mode.dart';
import 'package:openapi_client/src/model/tag_read.dart';
import 'package:openapi_client/src/model/tag_stat.dart';
import 'package:openapi_client/src/model/tag_update.dart';
import 'package:openapi_client/src/model/timer_read.dart';
import 'package:openapi_client/src/model/timer_update.dart';
import 'package:openapi_client/src/model/todo_create.dart';
import 'package:openapi_client/src/model/todo_include_reason.dart';
import 'package:openapi_client/src/model/todo_read.dart';
import 'package:openapi_client/src/model/todo_stats.dart';
import 'package:openapi_client/src/model/todo_status.dart';
import 'package:openapi_client/src/model/todo_update.dart';
import 'package:openapi_client/src/model/validation_error.dart';
import 'package:openapi_client/src/model/validation_error_loc_inner.dart';
import 'package:openapi_client/src/model/visibility_level.dart';
import 'package:openapi_client/src/model/visibility_settings.dart';

part 'serializers.g.dart';

@SerializersFor([
  CreateTodoOptions,
  FriendRead,
  FriendRequest,
  FriendshipRead,
  FriendshipStatus,
  HTTPValidationError,
  HolidayItem,
  PendingRequestRead,
  ResourceScope,
  ScheduleCreate,
  ScheduleRead,
  ScheduleState,
  ScheduleUpdate,
  TagCreate,
  TagGroupCreate,
  TagGroupRead,
  TagGroupReadWithTags,
  TagGroupUpdate,
  TagIncludeMode,
  TagRead,
  TagStat,
  TagUpdate,
  TimerRead,
  TimerUpdate,
  TodoCreate,
  TodoIncludeReason,
  TodoRead,
  TodoStats,
  TodoStatus,
  TodoUpdate,
  ValidationError,
  ValidationErrorLocInner,
  VisibilityLevel,
  VisibilitySettings,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(FriendRead)]),
        () => ListBuilder<FriendRead>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(HolidayItem)]),
        () => ListBuilder<HolidayItem>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(TagGroupReadWithTags)]),
        () => ListBuilder<TagGroupReadWithTags>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
        () => MapBuilder<String, JsonObject>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PendingRequestRead)]),
        () => ListBuilder<PendingRequestRead>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(TagRead)]),
        () => ListBuilder<TagRead>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ScheduleRead)]),
        () => ListBuilder<ScheduleRead>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(String)]),
        () => ListBuilder<String>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(TimerRead)]),
        () => ListBuilder<TimerRead>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(TodoRead)]),
        () => ListBuilder<TodoRead>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer()))
    .build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
