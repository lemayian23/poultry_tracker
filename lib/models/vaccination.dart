import 'package:hive/hive.dart';

part 'vaccination.g.dart';

@HiveType(typeId: 2)
class Vaccination {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String batchId;
  
  @HiveField(2)
  final String vaccineName;
  
  @HiveField(3)
  final DateTime dateGiven;
  
  @HiveField(4)
  final DateTime nextDueDate;
  
  @HiveField(5)
  final String? notes;
  
  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  final String? administeredBy;
  
  @HiveField(8)
  final double? dosage; // in ml
  
  @HiveField(9)
  final String? administrationRoute; // e.g., 'Oral', 'Injection', 'Water'
  
  @HiveField(10)
  final String? manufacturer;
  
  @HiveField(11)
  final String? batchNumber;

  Vaccination({
    required this.id,
    required this.batchId,
    required this.vaccineName,
    required this.dateGiven,
    required this.nextDueDate,
    this.notes,
    this.isCompleted = false,
    this.administeredBy,
    this.dosage,
    this.administrationRoute,
    this.manufacturer,
    this.batchNumber,
  });

  // Check if vaccination is due (within next 7 days)
  bool get isDueSoon {
    final now = DateTime.now();
    final daysUntilDue = nextDueDate.difference(now).inDays;
    return daysUntilDue <= 7 && daysUntilDue >= 0 && !isCompleted;
  }

  // Check if vaccination is overdue
  bool get isOverdue {
    return nextDueDate.isBefore(DateTime.now()) && !isCompleted;
  }

  // Get vaccination status for display
  String get status {
    if (isCompleted) return 'Completed';
    if (isOverdue) return 'Overdue';
    if (isDueSoon) return 'Due Soon';
    return 'Scheduled';
  }

  // Calculate days until/since due date
  int get daysFromDue {
    final now = DateTime.now();
    return nextDueDate.difference(now).inDays;
  }

  // Get formatted due status for display
  String get dueStatus {
    if (isCompleted) return 'Completed';
    
    final days = daysFromDue;
    if (days > 0) {
      return 'Due in $days day${days != 1 ? 's' : ''}';
    } else if (days < 0) {
      return 'Overdue by ${days.abs()} day${days.abs() != 1 ? 's' : ''}';
    } else {
      return 'Due today';
    }
  }

  // Validate vaccination data
  List<String> validate() {
    final errors = <String>[];
    
    if (vaccineName.isEmpty) {
      errors.add('Vaccine name is required');
    }
    
    if (dateGiven.isAfter(DateTime.now())) {
      errors.add('Date given cannot be in the future');
    }
    
    if (nextDueDate.isBefore(dateGiven)) {
      errors.add('Next due date cannot be before date given');
    }
    
    if (dosage != null && dosage! <= 0) {
      errors.add('Dosage must be greater than 0');
    }
    
    return errors;
  }

  // Check if vaccination is valid
  bool get isValid => validate().isEmpty;

  // Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'vaccineName': vaccineName,
      'dateGiven': dateGiven.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'notes': notes,
      'isCompleted': isCompleted,
      'administeredBy': administeredBy,
      'dosage': dosage,
      'administrationRoute': administrationRoute,
      'manufacturer': manufacturer,
      'batchNumber': batchNumber,
    };
  }

  // Create from map for deserialization
  factory Vaccination.fromMap(Map<String, dynamic> map) {
    return Vaccination(
      id: map['id'],
      batchId: map['batchId'],
      vaccineName: map['vaccineName'],
      dateGiven: DateTime.parse(map['dateGiven']),
      nextDueDate: DateTime.parse(map['nextDueDate']),
      notes: map['notes'],
      isCompleted: map['isCompleted'] ?? false,
      administeredBy: map['administeredBy'],
      dosage: map['dosage'] != null ? double.parse(map['dosage'].toString()) : null,
      administrationRoute: map['administrationRoute'],
      manufacturer: map['manufacturer'],
      batchNumber: map['batchNumber'],
    );
  }
}

// Common vaccine constants
class VaccineConstants {
  static const List<String> commonVaccines = [
    'Newcastle Disease (ND)',
    'Gumboro (IBD)',
    'Fowl Pox',
    'Marek\'s Disease',
    'Infectious Bronchitis (IB)',
    'Fowl Cholera',
    'Salmonella',
    'Coccidiosis',
    'Avian Influenza',
    'Infectious Coryza',
  ];

  static const List<String> administrationRoutes = [
    'Drinking Water',
    'Eye Drop',
    'Injection',
    'Spray',
    'Wing Web',
  ];

  static const List<String> commonManufacturers = [
    'MSD Animal Health',
    'Zoetis',
    'Boehringer Ingelheim',
    'Ceva',
    'Hipra',
    'Lohmann',
  ];
}

// Helper class for vaccination schedules
class VaccinationSchedule {
  static Map<String, List<Map<String, dynamic>>> commonSchedules = {
    'Broiler': [
      {'vaccine': 'Marek\'s Disease', 'day': 1, 'route': 'Injection'},
      {'vaccine': 'Newcastle Disease (ND)', 'day': 7, 'route': 'Eye Drop'},
      {'vaccine': 'Gumboro (IBD)', 'day': 14, 'route': 'Drinking Water'},
      {'vaccine': 'Infectious Bronchitis (IB)', 'day': 21, 'route': 'Spray'},
    ],
    'Layer': [
      {'vaccine': 'Marek\'s Disease', 'day': 1, 'route': 'Injection'},
      {'vaccine': 'Newcastle Disease (ND)', 'day': 7, 'route': 'Eye Drop'},
      {'vaccine': 'Gumboro (IBD)', 'day': 14, 'route': 'Drinking Water'},
      {'vaccine': 'Fowl Pox', 'day': 28, 'route': 'Wing Web'},
      {'vaccine': 'Infectious Bronchitis (IB)', 'day': 35, 'route': 'Spray'},
    ],
    'Kienyeji': [
      {'vaccine': 'Newcastle Disease (ND)', 'day': 1, 'route': 'Eye Drop'},
      {'vaccine': 'Gumboro (IBD)', 'day': 14, 'route': 'Drinking Water'},
      {'vaccine': 'Fowl Pox', 'day': 28, 'route': 'Wing Web'},
    ],
  };

  static List<Map<String, dynamic>> getScheduleForType(String birdType) {
    return commonSchedules[birdType] ?? [];
  }
}