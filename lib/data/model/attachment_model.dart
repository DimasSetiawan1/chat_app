import 'package:chat_apps/data/model/entity_model.dart';
import 'package:chat_apps/domain/entities/attachment.dart';

class AttachmentsModel implements EntityModel<Attachments> {
  final String type;
  final String url;
  final String thumbnailUrl;

  const AttachmentsModel({
    required this.type,
    required this.url,
    required this.thumbnailUrl,
  });

  factory AttachmentsModel.fromJson(Map<String, dynamic> json) => AttachmentsModel(
    type: json['type'] ?? '',
    url: json['url'] ?? '',
    thumbnailUrl: json['thumbnailUrl'] ?? '',
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
  };


  @override
Attachments get toEntity => Attachments(
    type: type,
    url: url,
    thumbnailUrl: thumbnailUrl,
  );

}