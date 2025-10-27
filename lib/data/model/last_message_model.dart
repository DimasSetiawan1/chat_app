import 'package:chat_apps/data/model/entity_model.dart';
import 'package:chat_apps/domain/entities/last_message.dart';
import 'package:chat_apps/sharing/utils/date_time_convert.dart';

class LastMessageModel implements EntityModel<LastMessage> {
  final String text;
  final String authorId;
  final String createdAt;

  const LastMessageModel({
    required this.text,
    required this.authorId,
    required this.createdAt,
  });

  factory LastMessageModel.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['createdAt'] as Object?;
    final createdAtStr = createdAtValue.toDateTime().toIso8601String();

    return LastMessageModel(
      text: json['text'] ?? '',
      authorId: json['authorId'] ?? '',
      createdAt: createdAtStr,
    );
  }
  @override
  Map<String, dynamic> toJson() => {
    'text': text,
    'authorId': authorId,
    'createdAt': createdAt,
  };

  @override
  LastMessage get toEntity =>
      LastMessage(text: text, authorId: authorId, createdAt: createdAt);
}
