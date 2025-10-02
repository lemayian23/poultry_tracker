import 'package:hive/hive.dart';
import '../models/subscription.dart';

class SubscriptionService {
  static final Map<String, Map<String, dynamic>> plans = {
    'monthly': {
      'name': 'Monthly Plan', 
      'price': 500.0, 
      'description': 'Unlimited batches, daily records'
    },
    'quarterly': {
      'name': 'Quarterly Plan', 
      'price': 1200.0, 
      'description': 'Everything in Monthly + Reports'
    },
    'yearly': {
      'name': 'Yearly Plan', 
      'price': 4000.0, 
      'description': 'Everything in Quarterly + Premium support'
    },
  };

  Future<Box<Subscription>> _openSubscriptionsBox() async {
    return await Hive.openBox<Subscription>('subscriptions');
  }

  Future<Map<String, dynamic>> processPayment({
    required String userId,
    required String plan,
    required String phoneNumber,
    required double amount,
  }) async {
    // TODO: integrate actual M-Pesa STK Push
    await Future.delayed(const Duration(seconds: 2));
    return {
      'success': true, 
      'checkoutRequestId': 'demo_${DateTime.now().millisecondsSinceEpoch}',
      'message': 'Payment processed successfully'
    };
  }

  Future<void> completeSubscription({
    required String userId,
    required String plan,
    required String checkoutRequestId,
    required double amount,
  }) async {
    final box = await _openSubscriptionsBox();
    final now = DateTime.now();
    final endDate = _calculateEndDate(plan, now);

    final subscription = Subscription(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      plan: plan,
      amount: amount,
      startDate: now,
      endDate: endDate,
      status: 'active', // FIXED: Added required status parameter
      mpesaReceiptNumber: checkoutRequestId,
    );

    await box.put(subscription.id, subscription);
  }

  Future<Subscription?> getCurrentSubscription(String userId) async {
    final box = await _openSubscriptionsBox();
    
    // Find the most recent active subscription for this user
    final subscriptions = box.values.where((sub) => sub.userId == userId).toList();
    if (subscriptions.isEmpty) return null;
    
    // Sort by start date descending and return the most recent
    subscriptions.sort((a, b) => b.startDate.compareTo(a.startDate));
    return subscriptions.first;
  }

  Future<bool> hasActiveSubscription(String userId) async {
    final subscription = await getCurrentSubscription(userId);
    return subscription?.isActive ?? false;
  }

  Future<List<Subscription>> getUserSubscriptions(String userId) async {
    final box = await _openSubscriptionsBox();
    return box.values.where((sub) => sub.userId == userId).toList();
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    final box = await _openSubscriptionsBox();
    final subscription = box.get(subscriptionId);
    
    if (subscription != null) {
      final updatedSubscription = Subscription(
        id: subscription.id,
        userId: subscription.userId,
        plan: subscription.plan,
        amount: subscription.amount,
        startDate: subscription.startDate,
        endDate: subscription.endDate,
        status: 'cancelled', // FIXED: Use status instead of isActive
        mpesaReceiptNumber: subscription.mpesaReceiptNumber,
      );
      await box.put(subscriptionId, updatedSubscription);
    }
  }

  DateTime _calculateEndDate(String plan, DateTime startDate) {
    switch (plan) {
      case 'monthly':
        return startDate.add(const Duration(days: 30));
      case 'quarterly':
        return startDate.add(const Duration(days: 90));
      case 'yearly':
        return startDate.add(const Duration(days: 365));
      default:
        return startDate.add(const Duration(days: 30));
    }
  }

  static double getPlanPrice(String plan) {
    return plans[plan]?['price'] ?? 0.0;
  }

  static String getPlanName(String plan) {
    return plans[plan]?['name'] ?? plan;
  }

  static String getPlanDescription(String plan) {
    return plans[plan]?['description'] ?? '';
  }

  // Check if user needs to subscribe (no active subscription)
  Future<bool> needsSubscription(String userId) async {
    final subscription = await getCurrentSubscription(userId);
    return subscription == null || !subscription.isActive;
  }
}