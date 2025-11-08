// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dropdown_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DropdownItemImpl _$$DropdownItemImplFromJson(Map<String, dynamic> json) =>
    _$DropdownItemImpl(
      value: json['value'] as String,
      label: json['label'] as String,
      order: (json['order'] as num).toInt(),
      active: json['active'] as bool,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$DropdownItemImplToJson(_$DropdownItemImpl instance) =>
    <String, dynamic>{
      'value': instance.value,
      'label': instance.label,
      'order': instance.order,
      'active': instance.active,
      'color': instance.color,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
