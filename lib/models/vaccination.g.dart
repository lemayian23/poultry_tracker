// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vaccination.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VaccinationAdapter extends TypeAdapter<Vaccination> {
  @override
  final int typeId = 2;

  @override
  Vaccination read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vaccination(
      id: fields[0] as String,
      batchId: fields[1] as String,
      vaccineName: fields[2] as String,
      dateGiven: fields[3] as DateTime,
      nextDueDate: fields[4] as DateTime,
      notes: fields[5] as String?,
      isCompleted: fields[6] as bool,
      administeredBy: fields[7] as String?,
      dosage: fields[8] as double?,
      administrationRoute: fields[9] as String?,
      manufacturer: fields[10] as String?,
      batchNumber: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Vaccination obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.batchId)
      ..writeByte(2)
      ..write(obj.vaccineName)
      ..writeByte(3)
      ..write(obj.dateGiven)
      ..writeByte(4)
      ..write(obj.nextDueDate)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.administeredBy)
      ..writeByte(8)
      ..write(obj.dosage)
      ..writeByte(9)
      ..write(obj.administrationRoute)
      ..writeByte(10)
      ..write(obj.manufacturer)
      ..writeByte(11)
      ..write(obj.batchNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaccinationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
