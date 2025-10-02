import 'package:flutter/material.dart';
import '../services/subscription_service.dart';

class MpesaPaymentScreen extends StatefulWidget {
  final String userId;
  final String plan;
  final double amount;

  const MpesaPaymentScreen({
    super.key,
    required this.userId,
    required this.plan,
    required this.amount,
  });

  @override
  State<MpesaPaymentScreen> createState() => _MpesaPaymentScreenState();
}

class _MpesaPaymentScreenState extends State<MpesaPaymentScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;
  String _statusMessage = '';
  bool _paymentSuccess = false;

  Map<String, dynamic> get _planData {
    return SubscriptionService.plans[widget.plan] ?? {
      'name': '${widget.plan[0].toUpperCase()}${widget.plan.substring(1)} Plan',
      'price': widget.amount,
      'description': 'Premium subscription'
    };
  }

  void _processPayment() async {
    final phoneNumber = _phoneController.text.trim();
    
    if (phoneNumber.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }

    // Validate phone number format
    if (!_isValidPhoneNumber(phoneNumber)) {
      _showError('Please enter a valid Kenyan phone number (e.g., 0712345678)');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Initiating M-Pesa payment...';
    });

    try {
      // Use demo mode for now since we don't have real M-Pesa credentials
      final result = await _subscriptionService.processPayment(
        userId: widget.userId,
        plan: widget.plan,
        phoneNumber: phoneNumber,
        amount: widget.amount,
      );

      if (result['success'] == true) {
        setState(() {
          _statusMessage = 'Payment initiated! Check your phone for STK Push.';
        });

        // Simulate payment completion (in real app, wait for callback)
        await _simulatePaymentCompletion(result['checkoutRequestId']);
      } else {
        _showError('Payment failed: ${result['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showError('Payment error: $e');
    } finally {
      if (!_paymentSuccess) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  bool _isValidPhoneNumber(String phone) {
    // Kenyan phone number validation: 07xxxxxxxx or 7xxxxxxxx
    final regex = RegExp(r'^(07\d{8}|7\d{8}|\+2547\d{8}|2547\d{8})$');
    return regex.hasMatch(phone.replaceAll(' ', ''));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    setState(() {
      _statusMessage = message;
    });
  }

  Future<void> _simulatePaymentCompletion(String checkoutRequestId) async {
    // Simulate waiting for payment confirmation
    await Future.delayed(const Duration(seconds: 3));

    try {
      await _subscriptionService.completeSubscription(
        userId: widget.userId,
        plan: widget.plan,
        checkoutRequestId: checkoutRequestId,
        amount: widget.amount,
      );

      setState(() {
        _paymentSuccess = true;
        _statusMessage = 'Payment successful! 🎉 Welcome to Pro.';
      });

      // Show success dialog and navigate
      _showSuccessDialog();
    } catch (e) {
      _showError('Payment verification failed: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Payment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan: ${_planData['name']}'),
            Text('Amount: KSh ${widget.amount}'),
            const SizedBox(height: 16),
            const Text(
              'Your subscription is now active! You can access all premium features.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  String _formatPhoneHint() {
    // Show appropriate hint based on common Kenyan formats
    return '0712345678';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M-Pesa Payment'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Plan:', _planData['name']),
                    _buildSummaryRow('Amount:', 'KSh ${widget.amount}'),
                    _buildSummaryRow('Description:', _planData['description']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Phone Input
            const Text(
              'Enter M-Pesa Phone Number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: _formatPhoneHint(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: _phoneController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _phoneController.clear(),
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 8),
            const Text(
              'You will receive an M-Pesa STK Push on this number',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _paymentSuccess
                      ? Colors.green.shade50
                      : _isProcessing
                          ? Colors.blue.shade50
                          : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _paymentSuccess
                        ? Colors.green
                        : _isProcessing
                            ? Colors.blue
                            : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _paymentSuccess
                          ? Icons.check_circle
                          : _isProcessing
                              ? Icons.hourglass_bottom
                              : Icons.info,
                      color: _paymentSuccess
                          ? Colors.green
                          : _isProcessing
                              ? Colors.blue
                              : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _paymentSuccess
                              ? Colors.green
                              : _isProcessing
                                  ? Colors.blue
                                  : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isProcessing
                  ? ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Processing Payment...'),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _paymentSuccess ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: 
                            _paymentSuccess ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _paymentSuccess ? 'PAYMENT COMPLETE' : 'PAY WITH M-PESA',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            
            const SizedBox(height: 16),
            
            // Demo notice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo Mode: No actual payment will be processed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: label == 'Amount:' ? Colors.green.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}