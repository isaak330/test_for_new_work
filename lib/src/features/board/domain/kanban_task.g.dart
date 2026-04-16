// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kanban_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KanbanTask _$KanbanTaskFromJson(Map<String, dynamic> json) => KanbanTask(
      id: KanbanTask._requiredIntFromJson(json['indicator_to_mo_id']),
      name: json['name'] as String,
      order: KanbanTask._requiredIntFromJson(json['order']),
      parentId: KanbanTask._nullableIntFromJson(json['parent_id']),
    );

Map<String, dynamic> _$KanbanTaskToJson(KanbanTask instance) =>
    <String, dynamic>{
      'indicator_to_mo_id': instance.id,
      'parent_id': instance.parentId,
      'name': instance.name,
      'order': instance.order,
    };
