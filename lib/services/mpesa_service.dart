import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class MpesaService {
  static const String _consumerKey = 'YOUR_CONSUMER_KEY';
  static const String _consumerSecret = 'YOUR_CONSUMER_SECRET';
  static const String _passkey = 'YOUR_PASSKEY';
  static const String _businessShortCode = '174379'; // Sandbox: 174379
  static const String _callbackUrl = 'https://yourdomain.com/callback';
  
  static const String _baseUrl = 'https://sandbox.safaricom.co.ke'; // Sandbox
  // static const String _baseUrl = 'https://api.safaricom.co.ke'; // Production

  // Generate access token
  Future<String> _getAccessToken() async {
    final credentials = base64.encode(utf8.encode('$_consumerKey:$_consumerSecret'));
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/oauth/v1/generate?grant_type=client_credentials'),
        headers: {'Authorization': 'Basic $credentials'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'] as String;
      } else {
        throw Exception('Failed to get access token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error while getting access token: $e');
    }
  }

  // Generate password for STK push
  String _generatePassword(String timestamp) {
    final data = '$_businessShortCode$_passkey$timestamp';
    return base64.encode(utf8.encode(data));
  }

  // Generate timestamp
  String _generateTimestamp() {
    final now = DateTime.now().toUtc();
    return '${now.year}${_pad(now.month)}${_pad(now.day)}${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
  }

  String _pad(int number) => number.toString().padLeft(2, '0');

  // Format phone number to 254 format
  String _formatPhoneNumber(String phoneNumber) {
    String formatted = phoneNumber.trim();
    
    if (formatted.startsWith('0')) {
      formatted = '254${formatted.substring(1)}';
    } else if (formatted.startsWith('+254')) {
      formatted = formatted.substring(1);
    } else if (formatted.startsWith('254')) {
      // Already in correct format
    } else if (formatted.startsWith('7')) {
      formatted = '254$formatted';
    }
    
    // Remove any non-digit characters
    formatted = formatted.replaceAll(RegExp(r'[^\d]'), '');
    
    if (formatted.length != 12) {
      throw Exception('Invalid phone number format. Expected 12 digits, got ${formatted.length}');
    }
    
    return formatted;
  }

  // Validate amount
  void _validateAmount(double amount) {
    if (amount <= 0) {
      throw Exception('Amount must be greater than 0');
    }
    if (amount > 150000) {
      throw Exception('Amount cannot exceed KSh 150,000');
    }
  }

  // Initiate STK Push
  Future<Map<String, dynamic>> initiateSTKPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    try {
      _validateAmount(amount);
      final accessToken = await _getAccessToken();
      final timestamp = _generateTimestamp();
      final password = _generatePassword(timestamp);
      final formattedPhone = _formatPhoneNumber(phoneNumber);

      final payload = {
        'BusinessShortCode': _businessShortCode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount.round(),
        'PartyA': formattedPhone,
        'PartyB': _businessShortCode,
        'PhoneNumber': formattedPhone,
        'CallBackURL': _callbackUrl,
        'AccountReference': accountReference,
        'TransactionDesc': transactionDesc,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpush/v1/processrequest'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      final responseBody = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception('STK Push failed: ${responseBody['errorMessage'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('M-Pesa error: $e');
    }
  }

  // Check transaction status
  Future<Map<String, dynamic>> checkTransactionStatus({
    required String checkoutRequestId,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      final timestamp = _generateTimestamp();
      final password = _generatePassword(timestamp);

      final payload = {
        'BusinessShortCode': _businessShortCode,
        'Password': password,
        'Timestamp': timestamp,
        'CheckoutRequestID': checkoutRequestId,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpushquery/v1/query'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      final responseBody = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception('Transaction status check failed: ${responseBody['errorMessage'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('M-Pesa status check error: $e');
    }
  }

  // Demo mode - simulate payment without actual M-Pesa
  Future<Map<String, dynamic>> initiateDemoPayment({
    required String phoneNumber,
    required double amount,
    required String accountReference,
  }) async {
    await Future.delayed(const Duration(seconds: 3)); // Simulate network delay
    
    final random = Random();
    final success = random.nextDouble() > 0.1; // 90% success rate for demo
    
    if (success) {
      return {
        'ResponseCode': '0',
        'ResponseDescription': 'Success',
        'MerchantRequestID': 'DEMO_${DateTime.now().millisecondsSinceEpoch}',
        'CheckoutRequestID': 'DEMO_${DateTime.now().millisecondsSinceEpoch + 1}',
        'CustomerMessage': 'Success. Request accepted for processing',
      };
    } else {
      throw Exception('Demo payment failed. Please try again.');
    }
  }

  // Check demo transaction status
  Future<Map<String, dynamic>> checkDemoTransactionStatus({
    required String checkoutRequestId,
  }) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    
    return {
      'ResponseCode': '0',
      'ResponseDescription': 'The service request has been accepted successfully',
      'MerchantRequestID': checkoutRequestId,
      'CheckoutRequestID': checkoutRequestId,
      'ResultCode': '0',
      'ResultDesc': 'The service request is processed successfully.',
    };
  }

  // Generate random receipt number for demo
  String generateDemoReceipt() {
    final random = Random();
    return '${random.nextInt(900000) + 100000}${random.nextInt(9000) + 1000}';
  }

  // Get service configuration
  Map<String, dynamic> getServiceConfig() {
    return {
      'isDemo': true, // Set to false when using real M-Pesa
      'businessShortCode': _businessShortCode,
      'maxAmount': 150000.0,
      'minAmount': 1.0,
    };
  }
}