// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerMessage _$ServerMessageFromJson(Map<String, dynamic> json) =>
    ServerMessage(
      level: $enumDecode(_$ServerMessageLevelEnumMap, json['level']),
      text: json['text'] as String,
    );

Map<String, dynamic> _$ServerMessageToJson(ServerMessage instance) =>
    <String, dynamic>{
      'level': _$ServerMessageLevelEnumMap[instance.level]!,
      'text': instance.text,
    };

const _$ServerMessageLevelEnumMap = {
  ServerMessageLevel.error: 'error',
  ServerMessageLevel.warning: 'warning',
  ServerMessageLevel.info: 'info',
};
