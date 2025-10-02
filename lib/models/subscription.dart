import 'package:hive/hive.dart';

part 'subscription.g.dart';

@HiveType(typeId: 3)
class Subscription {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String plan; // 'monthly', 'quarterly', 'yearly'
  
  @HiveField(3)
  final double amount;
  
  @HiveField(4)
  final DateTime startDate;
  
  @HiveField(5)
  final DateTime endDate;
  
  @HiveField(6)
  final String status; // 'active', 'expired', 'cancelled'
  
  @HiveField(7)
  final String? mpesaReceiptNumber;

  Subscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.mpesaReceiptNumber,
  });

  bool get isActive {
    final now = DateTime.now();
    return status == 'active' && endDate.isAfter(now) && startDate.isBefore(now);
  }

  bool get isExpired {
    return endDate.isBefore(DateTime.now()) || status == 'expired';
  }

  bool get isCancelled {
    return status == 'cancelled';
  }

  // Get days remaining in subscription
  int get daysRemaining {
    if (!isActive) return 0;
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  // Get subscription duration in days
  int get totalDuration {
    return endDate.difference(startDate).inDays;
  }

  // Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (!isActive) return 1.0;
    final totalDays = totalDuration.toDouble();
    final daysUsed = DateTime.now().difference(startDate).inDays.toDouble();
    return (daysUsed / totalDays).clamp(0.0, 1.0);
  }

  // Get formatted plan name
  String get formattedPlan {
    switch (plan) {
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'yearly':
        return 'Yearly';
      default:
        return plan;
    }
  }

  // Get plan duration in months
  int get planDurationInMonths {
    switch (plan) {
      case 'monthly':
        return 1;
      case 'quarterly':
        return 3;
      case 'yearly':
        return 12;
      default:
        return 1;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'plan': plan,
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'mpesaReceiptNumber': mpesaReceiptNumber,
      'isActive': isActive,
      'daysRemaining': daysRemaining,
      'formattedPlan': formattedPlan,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'],
      userId: map['userId'],
      plan: map['plan'],
      amount: (map['amount'] is int) ? (map['amount'] as int).toDouble() : map['amount'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      status: map['status'],
      mpesaReceiptNumber: map['mpesaReceiptNumber'],
    );
  }
}

// Subscription plans constants
class SubscriptionPlans {
  static const Map<String, Map<String, dynamic>> plans = {
    'monthly': {
      'name': 'Monthly',
      'price': 500.0,
      'duration': 30,
      'description': 'Perfect for small-scale farmers',
    },
    'quarterly': {
      'name': 'Quarterly',
      'price': 1200.0,
      'duration': 90,
      'description': 'Great value for medium farms',
      'savings': 'Save 20%',
    },
    'yearly': {
      'name': 'Yearly',
      'price': 4000.0,
      'duration': 365,
      'description': 'Best for commercial poultry farms',
      'savings': 'Save 33%',
    },
  };

  static double getPrice(String plan) {
    return plans[plan]?['price'] ?? 0.0;
  }

  static String getPlanName(String plan) {
    return plans[plan]?['name'] ?? plan;
  }

  static int getDuration(String plan) {
    return plans[plan]?['duration'] ?? 30;
  }
}