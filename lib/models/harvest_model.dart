import 'package:hive/hive.dart';

part 'harvest_model.g.dart';

@HiveType(typeId: 0)
class HarvestModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String cropType;

  @HiveField(2)
  late double quantity;

  @HiveField(3)
  late String unit;

  @HiveField(4)
  late DateTime harvestDate;

  HarvestModel({
    required this.id,
    required this.cropType,
    required this.quantity,
    required this.unit,
    required this.harvestDate,
  });

  factory HarvestModel.fromMap(Map<String, dynamic> map) {
    return HarvestModel(
      id: map['id'],
      cropType: map['crop_type'],
      quantity: map['quantity'],
      unit: map['unit'],
      harvestDate: DateTime.parse(map['harvest_date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'crop_type': cropType,
      'quantity': quantity,
      'unit': unit,
      'harvest_date': harvestDate.toIso8601String(),
    };
  }
}
