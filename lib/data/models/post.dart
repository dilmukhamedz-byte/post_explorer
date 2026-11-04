import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'post.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Post {
  @HiveField(0)
  @JsonKey(defaultValue: 0)
  final int id;

  @HiveField(1)
  @JsonKey(defaultValue: 0)
  final int userId;

  @HiveField(2)
  @JsonKey(defaultValue: '')
  final String title;

  @HiveField(3)
  @JsonKey(defaultValue: '')
  final String body;

  @HiveField(4)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isLocalCreated;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.isLocalCreated = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}