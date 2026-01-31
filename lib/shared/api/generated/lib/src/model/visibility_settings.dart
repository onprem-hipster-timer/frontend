//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:openapi_client/src/model/visibility_level.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'visibility_settings.g.dart';

/// 가시성 설정 DTO
///
/// Properties:
/// * [level] 
/// * [allowedUserIds] 
@BuiltValue()
abstract class VisibilitySettings implements Built<VisibilitySettings, VisibilitySettingsBuilder> {
  @BuiltValueField(wireName: r'level')
  VisibilityLevel? get level;
  // enum levelEnum {  private,  friends,  selected,  public,  };

  @BuiltValueField(wireName: r'allowed_user_ids')
  BuiltList<String>? get allowedUserIds;

  VisibilitySettings._();

  factory VisibilitySettings([void updates(VisibilitySettingsBuilder b)]) = _$VisibilitySettings;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VisibilitySettingsBuilder b) => b
      ..level = const ._(VisibilityLevel.private);

  @BuiltValueSerializer(custom: true)
  static Serializer<VisibilitySettings> get serializer => _$VisibilitySettingsSerializer();
}

class _$VisibilitySettingsSerializer implements PrimitiveSerializer<VisibilitySettings> {
  @override
  final Iterable<Type> types = const [VisibilitySettings, _$VisibilitySettings];

  @override
  final String wireName = r'VisibilitySettings';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VisibilitySettings object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.level != null) {
      yield r'level';
      yield serializers.serialize(
        object.level,
        specifiedType: const FullType(VisibilityLevel),
      );
    }
    if (object.allowedUserIds != null) {
      yield r'allowed_user_ids';
      yield serializers.serialize(
        object.allowedUserIds,
        specifiedType: const FullType.nullable(BuiltList, [FullType(String)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    VisibilitySettings object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VisibilitySettingsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'level':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(VisibilityLevel),
          ) as VisibilityLevel;
          result.level = valueDes;
          break;
        case r'allowed_user_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [FullType(String)]),
          ) as BuiltList<String>?;
          if (valueDes == null) continue;
          result.allowedUserIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  VisibilitySettings deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VisibilitySettingsBuilder();
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

