import 'package:flutter/material.dart';
import 'mpesa_payment_screen.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  final String userId;

  const SubscriptionPlansScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Upgrade to Pro',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unlock all features and manage your poultry farm efficiently',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Plans
            Expanded(
              child: ListView(
                children: [
                  _buildPlanCard(
                    context,
                    plan: 'monthly',
                    title: 'Monthly Plan',
                    price: 'KSh 500',
                    period: 'per month',
                    features: [
                      'Unlimited batches',
                      'Daily records tracking',
                      'Dashboard analytics',
                      'Vaccination reminders',
                      'Basic support',
                    ],
                    isPopular: false,
                  ),
                  const SizedBox(height: 16),
                  _buildPlanCard(
                    context,
                    plan: 'quarterly',
                    title: 'Quarterly Plan',
                    price: 'KSh 1,200',
                    period: 'every 3 months',
                    features: [
                      'Everything in Monthly',
                      'Save 20%',
                      'Priority support',
                      'Export reports',
                    ],
                    isPopular: true,
                  ),
                  const SizedBox(height: 16),
                  _buildPlanCard(
                    context,
                    plan: 'yearly',
                    title: 'Yearly Plan',
                    price: 'KSh 4,000',
                    period: 'per year',
                    features: [
                      'Everything in Quarterly',
                      'Save 33%',
                      'Premium support',
                      'Advanced analytics',
                      'Backup & sync',
                    ],
                    isPopular: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String plan,
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required bool isPopular,
  }) {
    return Card(
      elevation: 3,
      color: isPopular ? Colors.green.shade50 : Colors.white,
      child: Container(
        decoration: BoxDecoration(
          border: isPopular ? Border.all(color: Colors.green, width: 2) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isPopular) const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              Text(
                period,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _handlePlanSelection(context, plan);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Choose Plan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePlanSelection(BuildContext context, String plan) {
    // Get plan price
    final double price = _getPlanPrice(plan);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MpesaPaymentScreen(
          userId: userId,
          plan: plan,
          amount: price,
        ),
      ),
    );
  }

  double _getPlanPrice(String plan) {
    switch (plan) {
      case 'monthly':
        return 500.0;
      case 'quarterly':
        return 1200.0;
      case 'yearly':
        return 4000.0;
      default:
        return 500.0;
    }
  }
}