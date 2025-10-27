import 'package:chat_apps/data/model/entity_model.dart';
import 'package:chat_apps/domain/entities/meta.dart';

class MetaModel implements EntityModel<Meta> {
  final String topic;
  final String sessionId;
  

  const MetaModel({
    required this.topic,
    required this.sessionId,
  });

  factory MetaModel.fromJson(Map<String, dynamic> json) => MetaModel(
    topic: json['topic'] ?? '',
    sessionId: json['sessionId'] ?? '',
  );

  @override
  Map<String, dynamic> toJson() => {
    'topic': topic,
    'sessionId': sessionId,
  };


  @override
Meta get toEntity => Meta(
    topic: topic,
    sessionId: sessionId,
  );

}