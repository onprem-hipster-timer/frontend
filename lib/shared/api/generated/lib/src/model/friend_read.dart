//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'friend_read.g.dart';

/// 친구 정보 조회 DTO (간략화)
///
/// Properties:
/// * [userId] 
/// * [friendshipId] 
/// * [since] 
@BuiltValue()
abstract class FriendRead implements Built<FriendRead, FriendReadBuilder> {
  @BuiltValueField(wireName: r'user_id')
  String get userId;

  @BuiltValueField(wireName: r'friendship_id')
  String get friendshipId;

  @BuiltValueField(wireName: r'since')
  DateTime get since;

  FriendRead._();

  factory FriendRead([void updates(FriendReadBuilder b)]) = _$FriendRead;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FriendReadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FriendRead> get serializer => _$FriendReadSerializer();
}

class _$FriendReadSerializer implements PrimitiveSerializer<FriendRead> {
  @override
  final Iterable<Type> types = const [FriendRead, _$FriendRead];

  @override
  final String wireName = r'FriendRead';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FriendRead object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'user_id';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
    yield r'friendship_id';
    yield serializers.serialize(
      object.friendshipId,
      specifiedType: const FullType(String),
    );
    yield r'since';
    yield serializers.serialize(
      object.since,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FriendRead object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FriendReadBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'user_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.userId = valueDes;
          break;
        case r'friendship_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.friendshipId = valueDes;
          break;
        case r'since':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.since = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FriendRead deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FriendReadBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

