import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/driver_location.dart';
import '../models/travel_tracking.dart';
import '../models/pickup_queue.dart';
import '../models/weather_condition.dart';

class TrackingService {
  static const String baseUrl =
      'https://travel-api-production-23ae.up.railway.app';

  final String? token;

  TrackingService({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // Get driver location by travel ID
  Future<DriverLocation?> getDriverLocationByTravel(int travelId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/driver-location/$travelId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          return DriverLocation.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting driver location: $e');
      return null;
    }
  }

  // Get driver location by driver ID (legacy)
  Future<DriverLocation?> getDriverLocation(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/driver-location/driver/$driverId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          return DriverLocation.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting driver location: $e');
      return null;
    }
  }

  // Get travel tracking history
  Future<List<TravelTracking>> getTravelTracking(int travelId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tracking/travel/$travelId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['tracking'] != null) {
          return (data['tracking'] as List)
              .map((item) => TravelTracking.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting travel tracking: $e');
      return [];
    }
  }

  // Get latest travel status
  Future<TravelTracking?> getLatestTravelStatus(int travelId) async {
    try {
      final tracking = await getTravelTracking(travelId);
      if (tracking.isNotEmpty) {
        return tracking.first; // Assuming sorted by timestamp DESC
      }
      return null;
    } catch (e) {
      print('Error getting latest travel status: $e');
      return null;
    }
  }

  // Get pickup queue for a travel
  Future<List<PickupQueue>> getPickupQueue(int travelId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tracking/pickup-queue/$travelId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['queue'] != null) {
          return (data['queue'] as List)
              .map((item) => PickupQueue.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting pickup queue: $e');
      return [];
    }
  }

  // Get weather by coordinates
  Future<WeatherCondition?> getWeatherByCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/weather/coordinates?lat=$latitude&lon=$longitude'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['weather'] != null) {
          return WeatherCondition.fromJson(data['weather']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting weather: $e');
      return null;
    }
  }

  // Get weather by location name
  Future<WeatherCondition?> getWeatherByLocation(String location) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/weather/location?location=${Uri.encodeComponent(location)}'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['weather'] != null) {
          return WeatherCondition.fromJson(data['weather']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting weather by location: $e');
      return null;
    }
  }

  // Stream driver location updates (polling every 5 seconds)
  Stream<DriverLocation?> streamDriverLocation(int driverId) {
    return Stream.periodic(const Duration(seconds: 5), (_) async {
      return await getDriverLocation(driverId);
    }).asyncMap((future) => future);
  }

  // Stream travel status updates (polling every 10 seconds)
  Stream<TravelTracking?> streamTravelStatus(int travelId) {
    return Stream.periodic(const Duration(seconds: 10), (_) async {
      return await getLatestTravelStatus(travelId);
    }).asyncMap((future) => future);
  }

  // Stream pickup queue updates (polling every 10 seconds)
  Stream<List<PickupQueue>> streamPickupQueue(int travelId) {
    return Stream.periodic(const Duration(seconds: 10), (_) async {
      return await getPickupQueue(travelId);
    }).asyncMap((future) => future);
  }
}
