import 'dart:convert';
import 'package:http/http.dart' as http;

class OTPService {
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;
  OTPService._internal();

  final String baseUrl =
      'https://travel-api-production-23ae.up.railway.app/api';

  /// POST /api/auth/register
  /// Register new customer and send OTP email
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      print('📧 Registering customer: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': name,
          'phone': phone,
          'email': email,
          'password': password,
        }),
      );

      print('📧 Registration response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Registration successful: ${data['message']}');
        return {
          'success': true,
          'message': data['message'],
          'customerId': data['customerId'],
          'email': data['email'],
          'expiresIn': data['expiresIn'],
        };
      } else {
        final data = json.decode(response.body);
        print('❌ Registration failed: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Registrasi gagal',
        };
      }
    } catch (e) {
      print('❌ Registration error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// POST /api/auth/verify-otp
  /// Verify OTP code and activate customer account
  Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otpCode,
  }) async {
    try {
      print('🔐 Verifying OTP for: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otpCode': otpCode,
        }),
      );

      print('🔐 Verification response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ OTP verification successful');
        return {
          'success': true,
          'message': data['message'],
          'token': data['token'],
          'customer': data['customer'],
        };
      } else {
        final data = json.decode(response.body);
        print('❌ OTP verification failed: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Verifikasi gagal',
        };
      }
    } catch (e) {
      print('❌ Verification error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// POST /api/auth/resend-otp
  /// Resend OTP code to email
  Future<Map<String, dynamic>> resendOTP({
    required String email,
  }) async {
    try {
      print('📧 Resending OTP to: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      print('📧 Resend response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ OTP resent successfully');
        return {
          'success': true,
          'message': data['message'],
          'expiresIn': data['expiresIn'],
        };
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        final data = json.decode(response.body);
        print('⚠️  Rate limit: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Terlalu banyak percobaan',
        };
      } else {
        final data = json.decode(response.body);
        print('❌ Resend failed: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengirim ulang OTP',
        };
      }
    } catch (e) {
      print('❌ Resend error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}
