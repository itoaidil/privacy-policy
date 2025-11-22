import 'package:flutter/material.dart';
import '../models/po_model.dart';
import '../models/booking_model.dart';
import '../services/api_service.dart';

class TravelProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<POModel> _poList = [];
  List<String> _cities = [];
  List<String> _departureCities = [];
  List<String> _destinationCities = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<POModel> get poList => _poList;
  List<String> get cities => _cities;
  List<String> get departureCities => _departureCities;
  List<String> get destinationCities => _destinationCities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load daftar kota
  Future<void> loadCities() async {
    try {
      final result = await _apiService.getCities();
      if (result['success'] == true && result['data'] != null) {
        _cities = (result['data'] as List)
            .map((city) => city['name'].toString())
            .toList();
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Load daftar tempat berangkat dari database
  Future<void> loadDepartureCities() async {
    try {
      _departureCities = await _apiService.getDepartureCities();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Load daftar tujuan berdasarkan tempat berangkat
  Future<void> loadDestinationCities(String departureCity) async {
    try {
      _destinationCities =
          await _apiService.getDestinationCities(departureCity);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Reset daftar tujuan
  void resetDestinations() {
    _destinationCities = [];
    notifyListeners();
  }

  // Cari PO berdasarkan rute
  Future<void> searchPOs(String tempatBerangkat, String tujuan) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.searchPO(tempatBerangkat, tujuan);
      if (result['success'] == true && result['data'] != null) {
        _poList = (result['data'] as List)
            .map((po) => POModel(
                  id: po['id'],
                  nama: po['po_name'],
                  companyCode: po['company_code'],
                  email: po['email'],
                  phone: po['phone'],
                  address: po['address'],
                  vehicleCount: po['vehicle_count'],
                ))
            .toList();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Load semua PO - not available in API
  Future<void> loadAllPOs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // API doesn't have getAllPOs endpoint, return empty list
      _poList = [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Buat booking
  Future<BookingModel?> createBooking(BookingModel booking) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Note: API uses different structure than BookingModel
      // This method may need adjustment based on actual API usage
      _isLoading = false;
      notifyListeners();
      return booking;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
