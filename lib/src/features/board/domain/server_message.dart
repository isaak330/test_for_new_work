import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'server_message.g.dart';

enum ServerMessageLevel {
  error,
  warning,
  info,
}

@JsonSerializable()
class ServerMessage extends Equatable {
  const ServerMessage({
    required this.level,
    required this.text,
  });

  final ServerMessageLevel level;
  final String text;

  factory ServerMessage.fromJson(Map<String, dynamic> json) {
    return _$ServerMessageFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ServerMessageToJson(this);

  @override
  List<Object?> get props => [level, text];
}
