import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // Gunakan baseUrl lengkap (dengan /api) dari AppConfig
  final String baseUrl = AppConfig.baseUrl;

  // Helper method untuk handle HTTP errors
  Map<String, dynamic> _handleError(dynamic error) {
    return {
      'success': false,
      'message': error.toString(),
    };
  }

  // Helper method untuk parse response
  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to parse response: ${response.body}',
      };
    }
  }

  /// POST /api/payment/create-token
  /// Generate Snap token untuk pembayaran Midtrans
  ///
  /// Parameters:
  /// - bookingId: ID booking yang akan dibayar
  /// - amount: Jumlah pembayaran
  /// - customerName: Nama customer
  /// - customerEmail: Email customer
  /// - customerPhone: Nomor telepon customer (optional)
  ///
  /// Returns:
  /// {
  ///   "success": true,
  ///   "token": "abc123-token-xyz",
  ///   "redirect_url": "https://app.sandbox.midtrans.com/snap/v2/...",
  ///   "order_id": "TRAVEL-1-1234567890"
  /// }
  Future<Map<String, dynamic>> createPaymentToken({
    required int bookingId,
    required double amount,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
  }) async {
    try {
      print(
          '🟦 [PaymentService] Request create-token => $baseUrl/payment/create-token');
      print(
          '🟦 Payload: booking_id=$bookingId amount=$amount name=$customerName email=$customerEmail phone=${customerPhone ?? ''}');

      final response = await http.post(
        Uri.parse('$baseUrl/payment/create-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'booking_id': bookingId,
          'amount': amount,
          'customer_name': customerName,
          'customer_email': customerEmail,
          'customer_phone': customerPhone ?? '',
        }),
      );

      print('🟩 [PaymentService] Response status: ${response.statusCode}');
      print('🟩 [PaymentService] Response body: ${response.body}');

      final parsed = _parseResponse(response);
      print('🟩 [PaymentService] Parsed: $parsed');
      return parsed;
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/payment/status/{orderId}
  /// Cek status pembayaran manual
  ///
  /// Parameters:
  /// - orderId: Order ID dari Midtrans (format: TRAVEL-{bookingId}-{timestamp})
  ///
  /// Returns:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "transaction_status": "settlement",
  ///     "fraud_status": "accept",
  ///     "payment_type": "credit_card",
  ///     ...
  ///   }
  /// }
  Future<Map<String, dynamic>> checkPaymentStatus(String orderId) async {
    try {
      print(
          '🟦 [PaymentService] Request status => $baseUrl/payment/status/$orderId');
      final response = await http.get(
        Uri.parse('$baseUrl/payment/status/$orderId'),
      );
      print(
          '🟩 [PaymentService] Status response: ${response.statusCode} ${response.body}');
      final parsed = _parseResponse(response);
      print('🟩 [PaymentService] Parsed status: $parsed');
      return parsed;
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/payment/config
  /// Get Midtrans client key untuk frontend
  ///
  /// Returns:
  /// {
  ///   "success": true,
  ///   "client_key": "SB-Mid-client-xxxxxxxx"
  /// }
  Future<Map<String, dynamic>> getPaymentConfig() async {
    try {
      print('🟦 [PaymentService] Request config => $baseUrl/payment/config');
      final response = await http.get(
        Uri.parse('$baseUrl/payment/config'),
      );
      print(
          '🟩 [PaymentService] Config response: ${response.statusCode} ${response.body}');
      final parsed = _parseResponse(response);
      print('🟩 [PaymentService] Parsed config: $parsed');
      return parsed;
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/payment/test
  /// Test endpoint untuk verifikasi koneksi payment gateway
  ///
  /// Returns:
  /// {
  ///   "success": true,
  ///   "message": "Payment routes are working",
  ///   "environment": "sandbox"
  /// }
  Future<Map<String, dynamic>> testPaymentConnection() async {
    try {
      print('🟦 [PaymentService] Request test => $baseUrl/payment/test');
      final response = await http.get(
        Uri.parse('$baseUrl/payment/test'),
      );
      print(
          '🟩 [PaymentService] Test response: ${response.statusCode} ${response.body}');
      final parsed = _parseResponse(response);
      print('🟩 [PaymentService] Parsed test: $parsed');
      return parsed;
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST /api/payment/force-success
  /// Force update payment to success (UNTUK TESTING SANDBOX ONLY)
  ///
  /// Parameters:
  /// - orderId: Order ID dari Midtrans (format: TRAVEL-{bookingId}-{timestamp})
  ///
  /// Returns:
  /// {
  ///   "success": true,
  ///   "message": "Payment forced to success",
  ///   "updated": {
  ///     "payment_status": "paid",
  ///     "booking_status": "confirmed"
  ///   }
  /// }
  Future<Map<String, dynamic>> forcePaymentSuccess(String orderId) async {
    try {
      print(
          '🔴 [PaymentService] FORCE SUCCESS => $baseUrl/payment/force-success');
      print('🔴 Order ID: $orderId');

      final response = await http.post(
        Uri.parse('$baseUrl/payment/force-success'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': orderId,
        }),
      );

      print(
          '🟩 [PaymentService] Force success response: ${response.statusCode} ${response.body}');
      final parsed = _parseResponse(response);
      print('🟩 [PaymentService] Parsed force success: $parsed');
      return parsed;
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Helper method untuk format transaction status ke bahasa Indonesia
  String getTransactionStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'capture':
      case 'settlement':
        return 'Pembayaran Berhasil';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'deny':
        return 'Pembayaran Ditolak';
      case 'cancel':
        return 'Pembayaran Dibatalkan';
      case 'expire':
        return 'Pembayaran Kadaluarsa';
      case 'failure':
        return 'Pembayaran Gagal';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  /// Helper method untuk check apakah transaksi berhasil
  bool isTransactionSuccess(String status) {
    return status.toLowerCase() == 'capture' ||
        status.toLowerCase() == 'settlement';
  }

  /// Helper method untuk check apakah transaksi masih pending
  bool isTransactionPending(String status) {
    return status.toLowerCase() == 'pending';
  }

  /// Helper method untuk check apakah transaksi gagal
  bool isTransactionFailed(String status) {
    return status.toLowerCase() == 'deny' ||
        status.toLowerCase() == 'cancel' ||
        status.toLowerCase() == 'expire' ||
        status.toLowerCase() == 'failure';
  }
}
