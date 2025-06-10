// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FavoriteQuestAdapter extends TypeAdapter<FavoriteQuest> {
  @override
  final int typeId = 0;

  @override
  FavoriteQuest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FavoriteQuest(
      questId: fields[0] as String,
      userId: fields[1] as String,
      title: fields[2] as String,
      addedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FavoriteQuest obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.questId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.addedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteQuestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
