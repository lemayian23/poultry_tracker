import 'package:hive/hive.dart';

part 'batch.g.dart';

@HiveType(typeId: 0)
class Batch {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final DateTime startDate;
  
  @HiveField(3)
  final int initialBirds;
  
  @HiveField(4)
  final String type; // 'broiler', 'layer', 'kienyeji'
  
  @HiveField(5)
  bool isActive;
  
  @HiveField(6)
  final String? notes;

  Batch({
    required this.id,
    required this.name,
    required this.startDate,
    required this.initialBirds,
    required this.type,
    this.isActive = true,
    this.notes,
  });

  // Get current number of birds alive - FIXED VERSION
  int getCurrentBirds(int totalMortality) {
    return initialBirds - totalMortality;
  }

  // Get age in days
  int get ageInDays {
    return DateTime.now().difference(startDate).inDays;
  }

  // Convert to Map for easy display
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'initialBirds': initialBirds,
      'type': type,
      'isActive': isActive,
      'notes': notes,
    };
  }

  // Create from Map
  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'],
      name: map['name'],
      startDate: DateTime.parse(map['startDate']),
      initialBirds: map['initialBirds'],
      type: map['type'],
      isActive: map['isActive'] ?? true,
      notes: map['notes'],
    );
  }
}