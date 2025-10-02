import 'package:hive/hive.dart';

part 'daily_record.g.dart';

@HiveType(typeId: 1)
class DailyRecord {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String batchId;
  
  @HiveField(2)
  final DateTime date;
  
  @HiveField(3)
  int mortality;
  
  @HiveField(4)
  int eggsCollected;
  
  @HiveField(5)
  double feedConsumed; // in kg
  
  @HiveField(6)
  final String? notes;

  DailyRecord({
    required this.id,
    required this.batchId,
    required this.date,
    this.mortality = 0,
    this.eggsCollected = 0,
    this.feedConsumed = 0,
    this.notes,
  });

  // Helper method to check if record is for today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  // Helper method to get formatted date
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Convert to Map for easy display
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'date': date.toIso8601String(),
      'mortality': mortality,
      'eggsCollected': eggsCollected,
      'feedConsumed': feedConsumed,
      'notes': notes,
    };
  }

  // Create from Map
  factory DailyRecord.fromMap(Map<String, dynamic> map) {
    return DailyRecord(
      id: map['id'],
      batchId: map['batchId'],
      date: DateTime.parse(map['date']),
      mortality: map['mortality'] ?? 0,
      eggsCollected: map['eggsCollected'] ?? 0,
      feedConsumed: (map['feedConsumed'] ?? 0).toDouble(),
      notes: map['notes'],
    );
  }
}