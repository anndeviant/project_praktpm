import 'package:hive/hive.dart';

part 'favorite_model.g.dart';

@HiveType(typeId: 0)
class FavoriteQuest extends HiveObject {
  @HiveField(0)
  final String questId;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final DateTime addedAt;

  FavoriteQuest({
    required this.questId,
    required this.userId,
    required this.title,
    required this.addedAt,
  });
}
