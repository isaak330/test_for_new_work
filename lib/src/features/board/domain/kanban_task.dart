import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'kanban_task.g.dart';

@JsonSerializable()
class KanbanTask extends Equatable {
  const KanbanTask({
    required this.id,
    required this.name,
    required this.order,
    this.parentId,
    this.details = const <String, dynamic>{},
  });

  @JsonKey(
    name: 'indicator_to_mo_id',
    fromJson: _requiredIntFromJson,
  )
  final int id;
  @JsonKey(
    name: 'parent_id',
    fromJson: _nullableIntFromJson,
  )
  final int? parentId;
  final String name;
  @JsonKey(fromJson: _requiredIntFromJson)
  final int order;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Map<String, dynamic> details;

  KanbanTask copyWith({
    int? id,
    int? parentId,
    bool clearParentId = false,
    String? name,
    int? order,
    Map<String, dynamic>? details,
  }) {
    return KanbanTask(
      id: id ?? this.id,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      name: name ?? this.name,
      order: order ?? this.order,
      details: details ?? this.details,
    );
  }

  factory KanbanTask.fromJson(Map<String, dynamic> json) {
    final task = _$KanbanTaskFromJson(json);
    return task.copyWith(details: Map<String, dynamic>.from(json));
  }

  Map<String, dynamic> toJson() => _$KanbanTaskToJson(this);

  static int _requiredIntFromJson(Object? value) {
    return _asInt(value) ?? 0;
  }

  static int? _nullableIntFromJson(Object? value) {
    return _asInt(value);
  }

  static int? _asInt(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  @override
  List<Object?> get props => [id, parentId, name, order, details];
}
