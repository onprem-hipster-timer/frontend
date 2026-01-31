//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'friendship_status.g.dart';

class FriendshipStatus extends EnumClass {

  /// 친구 관계 상태
  @BuiltValueEnumConst(wireName: r'pending')
  static const FriendshipStatus pending = _$pending;
  /// 친구 관계 상태
  @BuiltValueEnumConst(wireName: r'accepted')
  static const FriendshipStatus accepted = _$accepted;
  /// 친구 관계 상태
  @BuiltValueEnumConst(wireName: r'blocked')
  static const FriendshipStatus blocked = _$blocked;

  static Serializer<FriendshipStatus> get serializer => _$friendshipStatusSerializer;

  const FriendshipStatus._(String name): super(name);

  static BuiltSet<FriendshipStatus> get values => _$values;
  static FriendshipStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class FriendshipStatusMixin = Object with _$FriendshipStatusMixin;

