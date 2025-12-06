import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/province_model.dart';
import '../config/app_config.dart';
import '../config/feature_flags.dart';

class ProvinceService {
  static String get baseUrl => AppConfig.baseUrl;

  // Get all active provinces
  Future<List<Province>> getAllProvinces() async {
    if (!Features.isProvinceFilteringEnabled) {
      Features.log('Province filtering disabled, returning empty list');
      return [];
    }

    try {
      Features.log('Fetching all provinces...');
      final response = await http.get(
        Uri.parse('$baseUrl/provinces'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> provincesList = data['data'];
          final provinces =
              provincesList.map((json) => Province.fromJson(json)).toList();
          Features.log('Loaded ${provinces.length} provinces');
          return provinces;
        }
      } else if (response.statusCode == 404) {
        // Feature not available on backend
        Features.log('Province endpoints not available (404)');
        return [];
      }

      Features.log('Failed to load provinces: ${response.statusCode}');
      return [];
    } catch (e) {
      Features.log('Error loading provinces: $e');
      return [];
    }
  }

  // Detect province from GPS coordinates
  Future<Province?> detectProvinceFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    if (!Features.isProvinceFilteringEnabled) {
      Features.log('Province filtering disabled, skipping detection');
      return null;
    }

    try {
      Features.log('Detecting province from coords: $latitude, $longitude');
      final response = await http.get(
        Uri.parse(
          '$baseUrl/provinces/detect?lat=$latitude&lng=$longitude',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final province = Province.fromJson(data['data']);
          Features.log('Detected province: ${province.name}');
          return province;
        }
      } else if (response.statusCode == 404) {
        Features.log('No province found for coordinates');
        return null;
      }

      Features.log('Failed to detect province: ${response.statusCode}');
      return null;
    } catch (e) {
      Features.log('Error detecting province: $e');
      return null;
    }
  }

  // Get province by ID
  Future<Province?> getProvinceById(int id) async {
    if (!Features.isProvinceFilteringEnabled) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/provinces/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Province.fromJson(data['data']);
        }
      }

      return null;
    } catch (e) {
      Features.log('Error getting province by ID: $e');
      return null;
    }
  }

  // Get cities in a province
  Future<List<String>> getCitiesByProvince(int provinceId) async {
    if (!Features.isProvinceFilteringEnabled) {
      return [];
    }

    try {
      Features.log('Fetching cities for province $provinceId');
      final response = await http.get(
        Uri.parse('$baseUrl/provinces/$provinceId/cities'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> citiesList = data['data'];
          final cities = citiesList
              .map((item) => item['city'] as String)
              .where((city) => city.isNotEmpty)
              .toList();
          Features.log('Loaded ${cities.length} cities');
          return cities;
        }
      }

      return [];
    } catch (e) {
      Features.log('Error getting cities: $e');
      return [];
    }
  }
}
