// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'harvest_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HarvestModelAdapter extends TypeAdapter<HarvestModel> {
  @override
  final int typeId = 0;

  @override
  HarvestModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HarvestModel(
      id: fields[0] as String,
      cropType: fields[1] as String,
      quantity: fields[2] as double,
      unit: fields[3] as String,
      harvestDate: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HarvestModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cropType)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.harvestDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HarvestModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
