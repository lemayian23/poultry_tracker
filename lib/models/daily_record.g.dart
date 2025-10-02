// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyRecordAdapter extends TypeAdapter<DailyRecord> {
  @override
  final int typeId = 1;

  @override
  DailyRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyRecord(
      id: fields[0] as String,
      batchId: fields[1] as String,
      date: fields[2] as DateTime,
      mortality: fields[3] as int,
      eggsCollected: fields[4] as int,
      feedConsumed: fields[5] as double,
      notes: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.batchId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.mortality)
      ..writeByte(4)
      ..write(obj.eggsCollected)
      ..writeByte(5)
      ..write(obj.feedConsumed)
      ..writeByte(6)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
