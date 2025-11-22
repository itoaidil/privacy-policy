import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Hardcoded untuk bypass Flutter web caching issue
  final String baseUrl =
      'https://travelapifresh-aw9m3822a-fitros-projects-1b98d7a0.vercel.app/api';

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

  // ==================== STUDENT ENDPOINTS ====================

  /// POST /api/student/login
  Future<Map<String, dynamic>> studentLogin(
      String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/student/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => http.Response(
              json.encode({
                'success': false,
                'message': 'Koneksi timeout. Server tidak merespon.',
              }),
              408,
            ),
          );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/student/departure-cities
  Future<List<String>> getDepartureCities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/student/departure-cities'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> cities = json.decode(response.body);
        return cities.map((city) => city.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// GET /api/student/destination-cities?from={from}
  Future<List<String>> getDestinationCities(String from) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/student/destination-cities?from=$from'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> cities = json.decode(response.body);
        return cities.map((city) => city.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// GET /api/student/search-po?from={from}&to={to}
  Future<Map<String, dynamic>> searchPO(String from, String to) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/student/search-po?from=$from&to=$to'),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/student/schedules?po_id={poId}&from={from}&to={to}&date={date}
  Future<Map<String, dynamic>> getSchedules({
    required int poId,
    required String from,
    required String to,
    String? date,
  }) async {
    try {
      String url = '$baseUrl/student/schedules?po_id=$poId&from=$from&to=$to';
      if (date != null && date.isNotEmpty) {
        url += '&date=$date';
      }

      final response = await http.get(Uri.parse(url));
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/student/travels/{travelId}/booked-seats
  Future<List<String>> getBookedSeats(int travelId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/student/travels/$travelId/booked-seats'),
      );

      final data = _parseResponse(response);
      if (data['success'] == true && data['data'] != null) {
        return List<String>.from(data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// GET /api/student/booked-seats?travel_id={travelId}
  Future<List<String>> getBookedSeatsQuery(int travelId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/student/booked-seats?travel_id=$travelId'),
      );

      final data = _parseResponse(response);
      if (data['success'] == true && data['bookedSeats'] != null) {
        return List<String>.from(data['bookedSeats']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// GET /api/student/travels?origin={origin}&destination={destination}&date={date}
  Future<Map<String, dynamic>> getTravels({
    String? origin,
    String? destination,
    String? date,
  }) async {
    try {
      String url = '$baseUrl/student/travels?';
      List<String> params = [];

      if (origin != null && origin.isNotEmpty) {
        params.add('origin=$origin');
      }
      if (destination != null && destination.isNotEmpty) {
        params.add('destination=$destination');
      }
      if (date != null && date.isNotEmpty) {
        params.add('date=$date');
      }

      url += params.join('&');

      final response = await http.get(Uri.parse(url));
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/student/travels/{id}
  Future<Map<String, dynamic>> getTravelDetail(int travelId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/student/travels/$travelId'),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/student/bookings/{studentId}
  Future<Map<String, dynamic>> getStudentBookings(int studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/student/bookings/$studentId'),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST /api/student/bookings
  Future<Map<String, dynamic>> createBooking({
    required int studentId,
    required int travelId,
    required String pickupLocation,
    required String dropoffLocation,
    required int numPassengers,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
    double? dropoffLat,
    double? dropoffLng,
    String? dropoffAddress,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/student/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': studentId,
          'travel_id': travelId,
          'pickup_location': pickupLocation,
          'dropoff_location': dropoffLocation,
          'num_passengers': numPassengers,
          'pickup_lat': pickupLat,
          'pickup_lng': pickupLng,
          'pickup_address': pickupAddress,
          'dropoff_lat': dropoffLat,
          'dropoff_lng': dropoffLng,
          'dropoff_address': dropoffAddress,
        }),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST /api/student/bookings-with-seats
  Future<Map<String, dynamic>> createBookingWithSeats({
    required int studentId,
    required int travelId,
    required String pickupLocation,
    required String dropoffLocation,
    required List<String> selectedSeats,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/student/bookings-with-seats'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': studentId,
          'travel_id': travelId,
          'pickup_location': pickupLocation,
          'dropoff_location': dropoffLocation,
          'selected_seats': selectedSeats,
        }),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/student/po-ratings
  Future<Map<String, dynamic>> getPOratings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/student/po-ratings'),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/student/po/{poId}/vehicles?origin={origin}&destination={destination}&date={date}
  Future<Map<String, dynamic>> getPOVehicles({
    required int poId,
    String? origin,
    String? destination,
    String? date,
  }) async {
    try {
      String url = '$baseUrl/student/po/$poId/vehicles?';
      List<String> params = [];

      if (origin != null && origin.isNotEmpty) {
        params.add('origin=$origin');
      }
      if (destination != null && destination.isNotEmpty) {
        params.add('destination=$destination');
      }
      if (date != null && date.isNotEmpty) {
        params.add('date=$date');
      }

      url += params.join('&');

      final response = await http.get(Uri.parse(url));
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== CUSTOMER ENDPOINTS ====================

  /// POST /api/customer/register
  Future<Map<String, dynamic>> customerRegister({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST /api/customer/login
  Future<Map<String, dynamic>> customerLogin(
      String email, String password) async {
    try {
      print('🔐 LOGIN REQUEST: $baseUrl/customer/login');
      print('📧 Email: $email');

      final response = await http
          .post(
        Uri.parse('$baseUrl/customer/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏱️ LOGIN TIMEOUT after 15 seconds');
          return http.Response(
            json.encode({
              'success': false,
              'message': 'Koneksi timeout. Server tidak merespon.',
            }),
            408,
          );
        },
      );

      print('📥 LOGIN RESPONSE STATUS: ${response.statusCode}');
      print('📦 LOGIN RESPONSE BODY: ${response.body}');

      final result = _parseResponse(response);
      print('✅ PARSED RESULT: $result');
      return result;
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/customer/pos-by-route?origin={origin}&destination={destination}
  Future<Map<String, dynamic>> getPOsByRoute({
    required String origin,
    required String destination,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/customer/pos-by-route?origin=$origin&destination=$destination'),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/customer/travels?origin={origin}&destination={destination}&date={date}
  Future<Map<String, dynamic>> getCustomerTravels({
    String? origin,
    String? destination,
    String? date,
  }) async {
    try {
      String url = '$baseUrl/customer/travels?';
      List<String> params = [];

      if (origin != null && origin.isNotEmpty) {
        params.add('origin=$origin');
      }
      if (destination != null && destination.isNotEmpty) {
        params.add('destination=$destination');
      }
      if (date != null && date.isNotEmpty) {
        params.add('date=$date');
      }

      url += params.join('&');

      final response = await http.get(Uri.parse(url));
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST /api/customer/booking
  Future<Map<String, dynamic>> createCustomerBooking({
    required int customerId,
    required int travelId,
    required List<String> selectedSeats,
    required String paymentMethod,
    required double totalPrice,
    String? pickupLocation,
    String? dropoffLocation,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
    double? dropoffLat,
    double? dropoffLng,
    String? dropoffAddress,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer/booking'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customer_id': customerId,
          'travel_id': travelId,
          'selected_seats': selectedSeats,
          'payment_method': paymentMethod,
          'total_price': totalPrice,
          'pickup_location': pickupLocation,
          'dropoff_location': dropoffLocation,
          'pickup_lat': pickupLat,
          'pickup_lng': pickupLng,
          'pickup_address': pickupAddress,
          'dropoff_lat': dropoffLat,
          'dropoff_lng': dropoffLng,
          'dropoff_address': dropoffAddress,
        }),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/customer/bookings/{customerId}
  Future<Map<String, dynamic>> getCustomerBookings(int customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer/bookings/$customerId'),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/customer/profile/{customerId}
  Future<Map<String, dynamic>> getCustomerProfile(int customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer/profile/$customerId'),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== DRIVER ENDPOINTS ====================

  /// GET /api/driver/travels/{driverId}
  Future<Map<String, dynamic>> getDriverTravels(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver/travels/$driverId'),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/driver/travels/{travelId}/bookings
  Future<Map<String, dynamic>> getTravelBookings(int travelId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver/travels/$travelId/bookings'),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// PUT /api/driver/travels/{travelId}/status
  Future<Map<String, dynamic>> updateTravelStatus({
    required int travelId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/driver/travels/$travelId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': status,
        }),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== PO ENDPOINTS ====================

  /// POST /api/po/login
  Future<Map<String, dynamic>> poLogin(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/po/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/po/{poId}/vehicles
  Future<Map<String, dynamic>> getPOVehiclesList(int poId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/po/$poId/vehicles'),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/po/{poId}/travels
  Future<Map<String, dynamic>> getPOTravels(int poId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/po/$poId/travels'),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/po/{poId}/bookings
  Future<Map<String, dynamic>> getPOBookings(int poId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/po/$poId/bookings'),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET /api/po/cities
  Future<Map<String, dynamic>> getCities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/po/cities'),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==================== HEALTH CHECK ====================

  /// GET /health
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl.replaceAll('/api', '')}/health'),
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }
}
