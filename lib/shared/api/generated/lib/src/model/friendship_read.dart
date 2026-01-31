//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:momeet_api/src/model/friendship_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'friendship_read.g.dart';

/// 친구 관계 조회 DTO
///
/// Properties:
/// * [id] 
/// * [requesterId] 
/// * [addresseeId] 
/// * [status] 
/// * [blockedBy] 
/// * [createdAt] 
/// * [updatedAt] 
@BuiltValue()
abstract class FriendshipRead implements Built<FriendshipRead, FriendshipReadBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'requester_id')
  String get requesterId;

  @BuiltValueField(wireName: r'addressee_id')
  String get addresseeId;

  @BuiltValueField(wireName: r'status')
  FriendshipStatus get status;
  // enum statusEnum {  pending,  accepted,  blocked,  };

  @BuiltValueField(wireName: r'blocked_by')
  String? get blockedBy;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  FriendshipRead._();

  factory FriendshipRead([void updates(FriendshipReadBuilder b)]) = _$FriendshipRead;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FriendshipReadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FriendshipRead> get serializer => _$FriendshipReadSerializer();
}

class _$FriendshipReadSerializer implements PrimitiveSerializer<FriendshipRead> {
  @override
  final Iterable<Type> types = const [FriendshipRead, _$FriendshipRead];

  @override
  final String wireName = r'FriendshipRead';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FriendshipRead object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'requester_id';
    yield serializers.serialize(
      object.requesterId,
      specifiedType: const FullType(String),
    );
    yield r'addressee_id';
    yield serializers.serialize(
      object.addresseeId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(FriendshipStatus),
    );
    if (object.blockedBy != null) {
      yield r'blocked_by';
      yield serializers.serialize(
        object.blockedBy,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FriendshipRead object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FriendshipReadBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'requester_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.requesterId = valueDes;
          break;
        case r'addressee_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.addresseeId = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(FriendshipStatus),
          ) as FriendshipStatus;
          result.status = valueDes;
          break;
        case r'blocked_by':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.blockedBy = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FriendshipRead deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FriendshipReadBuilder();
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

