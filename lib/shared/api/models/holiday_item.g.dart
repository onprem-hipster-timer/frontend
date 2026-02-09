// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holiday_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HolidayItem _$HolidayItemFromJson(Map<String, dynamic> json) => _HolidayItem(
      locdate: json['locdate'] as String,
      seq: (json['seq'] as num).toInt(),
      dateKind: json['dateKind'] as String,
      dateName: json['dateName'] as String,
      isHoliday: json['isHoliday'] as bool,
    );

Map<String, dynamic> _$HolidayItemToJson(_HolidayItem instance) =>
    <String, dynamic>{
      'locdate': instance.locdate,
      'seq': instance.seq,
      'dateKind': instance.dateKind,
      'dateName': instance.dateName,
      'isHoliday': instance.isHoliday,
    };
