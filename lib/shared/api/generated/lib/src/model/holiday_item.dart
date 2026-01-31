//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'holiday_item.g.dart';

/// 도메인 국경일 정보 항목 (정제된 데이터)
///
/// Properties:
/// * [locdate] 
/// * [seq] 
/// * [dateKind] 
/// * [dateName] 
/// * [isHoliday] 
@BuiltValue()
abstract class HolidayItem implements Built<HolidayItem, HolidayItemBuilder> {
  @BuiltValueField(wireName: r'locdate')
  String get locdate;

  @BuiltValueField(wireName: r'seq')
  int get seq;

  @BuiltValueField(wireName: r'dateKind')
  String get dateKind;

  @BuiltValueField(wireName: r'dateName')
  String get dateName;

  @BuiltValueField(wireName: r'isHoliday')
  bool get isHoliday;

  HolidayItem._();

  factory HolidayItem([void updates(HolidayItemBuilder b)]) = _$HolidayItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(HolidayItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<HolidayItem> get serializer => _$HolidayItemSerializer();
}

class _$HolidayItemSerializer implements PrimitiveSerializer<HolidayItem> {
  @override
  final Iterable<Type> types = const [HolidayItem, _$HolidayItem];

  @override
  final String wireName = r'HolidayItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    HolidayItem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'locdate';
    yield serializers.serialize(
      object.locdate,
      specifiedType: const FullType(String),
    );
    yield r'seq';
    yield serializers.serialize(
      object.seq,
      specifiedType: const FullType(int),
    );
    yield r'dateKind';
    yield serializers.serialize(
      object.dateKind,
      specifiedType: const FullType(String),
    );
    yield r'dateName';
    yield serializers.serialize(
      object.dateName,
      specifiedType: const FullType(String),
    );
    yield r'isHoliday';
    yield serializers.serialize(
      object.isHoliday,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    HolidayItem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required HolidayItemBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'locdate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.locdate = valueDes;
          break;
        case r'seq':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.seq = valueDes;
          break;
        case r'dateKind':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.dateKind = valueDes;
          break;
        case r'dateName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.dateName = valueDes;
          break;
        case r'isHoliday':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isHoliday = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  HolidayItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = HolidayItemBuilder();
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

