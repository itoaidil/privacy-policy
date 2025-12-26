import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/travel_provider.dart';
import '../models/po_model.dart';
import 'po_detail_screen.dart';
import 'map_picker_screen.dart';
import 'location_picker_screen.dart';
import '../services/location_service.dart';
import '../services/province_service.dart';
import '../models/province_model.dart';
import '../config/feature_flags.dart';
import '../config/app_config.dart';

// Model untuk Location dari API
class Location {
  final int id;
  final String name;
  final String type;
  final String? parentName;
  final bool isPopular;
  final String displayName;

  Location({
    required this.id,
    required this.name,
    required this.type,
    this.parentName,
    required this.isPopular,
    required this.displayName,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      parentName: json['parent_name'],
      isPopular: json['is_popular'] == 1,
      displayName: json['display_name'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _tempatBerangkat; // Nama asli untuk API
  String? _tujuan; // Nama asli untuk API
  String? _tempatBerangkatDisplay; // Display name untuk UI
  String? _tujuanDisplay; // Display name untuk UI
  DateTime? _tanggalBerangkat;
  final _formKey = GlobalKey<FormState>();
  final _departureController = TextEditingController();
  final _destinationController = TextEditingController();
  final _dateController = TextEditingController();
  // Optional pickup/dropoff selections
  String? _pickupAddress;
  String? _dropoffAddress;
  Map<String, double>? _pickupCoord; // {lat, lng}
  Map<String, double>? _dropoffCoord;

  // Location service
  final LocationService _locationService = LocationService();
  bool _isLoadingLocation = false;
  bool _hasAutoDetectedLocation = false;

  // Province service (NEW - for filtering)
  final ProvinceService _provinceService = ProvinceService();
  Province? _detectedProvince;
  Province? _selectedProvince;
  bool _isDetectingProvince = false;

  // Fetch locations dari API
  // NEW: Support province filtering jika feature enabled
  Future<List<Location>> fetchLocations(String query) async {
    try {
      // Build URL - SEARCH ALL LOCATIONS (no province filter)
      // User can search any location in Indonesia regardless of their GPS
      String url = '${AppConfig.baseUrl}/locations?search=$query&limit=30';

      // DISABLED: Province filter removed to allow cross-province search
      // User can book travel from any province (e.g., GPS in Yogya, book Padang travel)
      // Province tracking still works - GPS saved for analytics only

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final locations = (data['data'] as List)
            .map((item) => Location.fromJson(item))
            .toList();

        Features.log('Fetched ${locations.length} locations for query: $query');
        return locations;
      }
      return [];
    } catch (e) {
      print('Error fetching locations: $e');
      return [];
    }
  }

  // Fetch popular locations untuk default suggestions
  Future<List<Location>> fetchPopularLocations() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://travel-api-production-23ae.up.railway.app/api/locations/popular'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final locations = (data['data'] as List)
            .map((item) => Location.fromJson(item))
            .toList();
        return locations;
      }
      return [];
    } catch (e) {
      print('Error fetching popular locations: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    // Load daftar tempat berangkat saat pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TravelProvider>().loadDepartureCities();

      // NEW: Province detection jika feature enabled
      if (Features.isProvinceFilteringEnabled) {
        _loadSavedProvince(); // Load dari local storage dulu
      } else {
        // OLD: Location detection (existing behavior)
        _autoDetectUserLocation();
      }
    });
  }

  /// NEW: Load saved province dari SharedPreferences
  Future<void> _loadSavedProvince() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedProvinceId = prefs.getInt('selected_province_id');
      final savedProvinceName = prefs.getString('selected_province_name');
      final savedProvinceCode = prefs.getString('selected_province_code');

      if (savedProvinceId != null &&
          savedProvinceName != null &&
          savedProvinceCode != null) {
        // Province sudah pernah tersimpan, langsung gunakan
        final province = Province(
          id: savedProvinceId,
          name: savedProvinceName,
          code: savedProvinceCode,
        );
        setState(() {
          _selectedProvince = province;
          _hasAutoDetectedLocation = true; // Tandai sudah ada province
        });
        Features.log('Loaded saved province: $savedProvinceName (from cache)');

        // NO SNACKBAR saat load from cache - sudah tidak perlu notifikasi lagi
      } else {
        // Belum ada saved province, detect dari GPS
        _autoDetectProvince();
      }
    } catch (e) {
      Features.log('Error loading saved province: $e');
      _autoDetectProvince(); // Fallback ke GPS detection
    }
  }

  /// NEW: Save province ke SharedPreferences
  Future<void> _saveProvince(Province province) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_province_id', province.id);
      await prefs.setString('selected_province_name', province.name);
      await prefs.setString('selected_province_code', province.code);
      Features.log('Saved province: ${province.name}');
    } catch (e) {
      Features.log('Error saving province: $e');
    }
  }

  /// NEW: Auto-detect province dari GPS (Province Filtering Feature)
  Future<void> _autoDetectProvince() async {
    if (_hasAutoDetectedLocation) return;

    setState(() => _isDetectingProvince = true);

    try {
      Features.log('Starting province detection...');

      // Get current location
      final locationData =
          await _locationService.getCurrentLocationWithAddress();

      if (locationData != null && mounted) {
        final address = locationData['address'] as String;
        final lat = locationData['latitude'] as double;
        final lng = locationData['longitude'] as double;

        // Detect province from coordinates
        final province =
            await _provinceService.detectProvinceFromCoordinates(lat, lng);

        if (province != null && mounted) {
          setState(() {
            _detectedProvince = province;
            _selectedProvince = province; // Auto-select detected province
            _pickupAddress = address;
            _pickupCoord = {'lat': lat, 'lng': lng};
            _hasAutoDetectedLocation = true;
          });

          // IMPORTANT: Save province ke local storage
          await _saveProvince(province);

          Features.log('Province detected and saved: ${province.name}');
          // NO SNACKBAR - Silent province detection
        } else {
          // Province not found, fallback to old location detection
          Features.log('Province not detected, using fallback');
          _autoDetectUserLocation();
        }
      }
    } catch (e) {
      Features.log('Error detecting province: $e');
      // Fallback to old location detection
      _autoDetectUserLocation();
    } finally {
      if (mounted) {
        setState(() => _isDetectingProvince = false);
      }
    }
  }

  /// Auto-detect lokasi user saat pertama kali buka
  Future<void> _autoDetectUserLocation() async {
    if (_hasAutoDetectedLocation) return; // Sudah pernah detect

    setState(() => _isLoadingLocation = true);

    try {
      final locationData =
          await _locationService.getCurrentLocationWithAddress();

      if (locationData != null && mounted) {
        final address = locationData['address'] as String;
        final lat = locationData['latitude'] as double;
        final lng = locationData['longitude'] as double;

        // Ambil nama kota dari address untuk API
        final cityName = _extractCityFromAddress(address);

        setState(() {
          _pickupAddress = address;
          _pickupCoord = {'lat': lat, 'lng': lng};
          _hasAutoDetectedLocation = true;

          // Set tempat berangkat jika berhasil extract city
          if (cityName != null) {
            _tempatBerangkat = cityName;
            _tempatBerangkatDisplay = cityName;
            _departureController.text = cityName;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Lokasi Anda: ${address.length > 50 ? address.substring(0, 50) + '...' : address}'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error auto-detecting location: \$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Tidak bisa mendeteksi lokasi. Silakan pilih manual.'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _autoDetectUserLocation(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  /// Extract nama kota dari address string
  String? _extractCityFromAddress(String address) {
    // Format address biasanya: Jalan, Kelurahan, Kecamatan, Kota, Provinsi
    final parts = address.split(',').map((e) => e.trim()).toList();

    // Cari yang mengandung kata kunci kota
    for (var part in parts) {
      // Skip jalan dan kelurahan (biasanya di awal)
      if (part.toLowerCase().contains('jl') ||
          part.toLowerCase().contains('jalan')) continue;

      // Ambil yang mengandung nama kota besar
      if (part.toLowerCase().contains('padang') ||
          part.toLowerCase().contains('bukittinggi') ||
          part.toLowerCase().contains('payakumbuh') ||
          part.toLowerCase().contains('solok') ||
          part.toLowerCase().contains('pariaman') ||
          part.toLowerCase().contains('jakarta') ||
          part.toLowerCase().contains('bandung') ||
          part.toLowerCase().contains('medan') ||
          part.toLowerCase().contains('surabaya')) {
        return part;
      }
    }

    // Fallback: ambil part ketiga atau keempat (biasanya kota)
    if (parts.length >= 4) return parts[3];
    if (parts.length >= 3) return parts[2];

    return null;
  }

  Future<void> _pickLocation({required bool isPickup}) async {
    final city = isPickup ? _tempatBerangkat : _tujuan;
    if (city == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pilih kota terlebih dahulu'),
      ));
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          title: isPickup ? 'Pilih Titik Jemput' : 'Pilih Titik Antar',
          initialCity: city,
        ),
      ),
    );
    if (result != null && result is Map) {
      setState(() {
        if (isPickup) {
          _pickupAddress = result['address'] as String?;
          _pickupCoord = {
            'lat': (result['lat'] as num).toDouble(),
            'lng': (result['lng'] as num).toDouble(),
          };
        } else {
          _dropoffAddress = result['address'] as String?;
          _dropoffCoord = {
            'lat': (result['lat'] as num).toDouble(),
            'lng': (result['lng'] as num).toDouble(),
          };
        }
      });
    }
  }

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggalBerangkat ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D47A1),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _tanggalBerangkat) {
      setState(() {
        _tanggalBerangkat = picked;
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  // Check if user GPS province is different from departure location province
  Future<bool> _checkProvinceMismatch() async {
    print('🔍 Province Mismatch Check START');
    print(
        '   Selected Province: ${_selectedProvince?.name} (ID: ${_selectedProvince?.id})');
    print('   Departure Location: $_tempatBerangkat');

    // If no province detected or no departure location, skip check
    if (_selectedProvince == null || _tempatBerangkat == null) {
      print('   ⚠️ Province or departure is null - skipping check');
      return true; // Allow to proceed
    }

    try {
      // Get province info for departure location
      final url =
          '${AppConfig.baseUrl}/locations?search=$_tempatBerangkat&limit=1';
      print('   🌐 API Request: $url');

      final response = await http.get(Uri.parse(url));
      print('   📡 API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('   📦 API Data: $data');

        if (data['data'] != null && (data['data'] as List).isNotEmpty) {
          final locationData = data['data'][0];
          final departureProvinceId = locationData['province_id'];

          print('   🏛️ Departure Province ID: $departureProvinceId');
          print('   📍 User GPS Province ID: ${_selectedProvince!.id}');

          // If province IDs are different, show warning dialog
          if (departureProvinceId != null &&
              departureProvinceId != _selectedProvince!.id) {
            print('   ⚠️ MISMATCH DETECTED! Showing dialog...');
            return await _showProvinceWarningDialog();
          } else {
            print(
                '   ✅ Same province or departure has no province - no warning needed');
          }
        }
      }
    } catch (e) {
      print('   ❌ Error checking province mismatch: $e');
    }

    print('   ✅ Province check complete - allowing to proceed');
    return true; // Default: allow to proceed
  }

  // Show warning dialog when user GPS province differs from departure location
  Future<bool> _showProvinceWarningDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Lokasi Jauh',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                'Anda berada jauh dari lokasi pemesanan. Anda Memilih tempat berangkat $_tempatBerangkatDisplay. Apakah pemesanan tetap dilanjutkan?',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              actions: [
                // Kembali button (white/grey)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Kembali',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Lanjut button (blue)
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Lanjut',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed
  }

  void _searchTravel() async {
    if (_formKey.currentState!.validate()) {
      if (_tempatBerangkat == _tujuan) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tempat berangkat dan tujuan tidak boleh sama!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check for province mismatch and show warning if needed
      final shouldProceed = await _checkProvinceMismatch();

      if (!shouldProceed) {
        return; // User chose "Kembali"
      }

      // Search PO berdasarkan rute
      context.read<TravelProvider>().searchPOs(
            _tempatBerangkat!,
            _tujuan!,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TravelProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Travel Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF1976D2),
                  ],
                ),
              ),
              padding: const EdgeInsets.only(top: 20, bottom: 40),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 8,
                        shadowColor: Colors.blue.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Province detection removed - silent filtering

                              // Loading province indicator
                              if (_isDetectingProvince)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.blue[700]!,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Mendeteksi lokasi Anda...',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Error message
                              if (provider.errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.red[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline,
                                            color: Colors.red[700]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            provider.errorMessage!,
                                            style: TextStyle(
                                                color: Colors.red[700]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              InkWell(
                                onTap: () async {
                                  final location =
                                      await Navigator.push<Location>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          LocationPickerScreen(
                                        title: 'Pilih Tempat Berangkat',
                                        provinceId:
                                            Features.isProvinceFilteringEnabled &&
                                                    _selectedProvince != null
                                                ? _selectedProvince!.id
                                                : null,
                                      ),
                                    ),
                                  );

                                  if (location != null) {
                                    setState(() {
                                      _tempatBerangkat = location.name;
                                      _tempatBerangkatDisplay =
                                          location.displayName;
                                      _departureController.text =
                                          location.displayName;
                                      _tujuan = null;
                                      _tujuanDisplay = null;
                                      _destinationController.clear();
                                    });
                                    provider
                                        .loadDestinationCities(location.name);
                                  }
                                },
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller: _departureController,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Tempat Berangkat',
                                      labelStyle: GoogleFonts.poppins(),
                                      prefixIcon: Container(
                                        padding: const EdgeInsets.all(12),
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Color(0xFF0D47A1),
                                        ),
                                      ),
                                      suffixIcon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.search,
                                            color: Colors.grey[400],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.swap_vert,
                                              color: Color(0xFF0D47A1),
                                            ),
                                            onPressed: () {
                                              if (_tempatBerangkat != null &&
                                                  _tujuan != null) {
                                                setState(() {
                                                  // Swap values directly
                                                  final temp = _tempatBerangkat;
                                                  _tempatBerangkat = _tujuan;
                                                  _tujuan = temp;

                                                  // Swap display names
                                                  final tempDisplay =
                                                      _tempatBerangkatDisplay;
                                                  _tempatBerangkatDisplay =
                                                      _tujuanDisplay;
                                                  _tujuanDisplay = tempDisplay;

                                                  // Swap text
                                                  final tempText =
                                                      _departureController.text;
                                                  _departureController.text =
                                                      _destinationController
                                                          .text;
                                                  _destinationController.text =
                                                      tempText;
                                                });

                                                // Reload destinations
                                                provider.loadDestinationCities(
                                                    _tempatBerangkat!);

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content:
                                                        Text('Lokasi ditukar!'),
                                                    duration: Duration(
                                                        milliseconds: 600),
                                                    backgroundColor:
                                                        Color(0xFF0D47A1),
                                                  ),
                                                );
                                              }
                                            },
                                            tooltip: 'Tukar lokasi',
                                          ),
                                        ],
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF0D47A1),
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText:
                                          'Ketuk untuk pilih tempat berangkat',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Pilih tempat berangkat';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              InkWell(
                                onTap: _tempatBerangkat == null
                                    ? null
                                    : () async {
                                        final location =
                                            await Navigator.push<Location>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                LocationPickerScreen(
                                              title: 'Pilih Tujuan',
                                              provinceId: Features
                                                          .isProvinceFilteringEnabled &&
                                                      _selectedProvince != null
                                                  ? _selectedProvince!.id
                                                  : null,
                                            ),
                                          ),
                                        );

                                        if (location != null) {
                                          setState(() {
                                            _tujuan = location.name;
                                            _tujuanDisplay =
                                                location.displayName;
                                            _destinationController.text =
                                                location.displayName;
                                          });
                                        }
                                      },
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller: _destinationController,
                                    enabled: _tempatBerangkat != null,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Tujuan',
                                      labelStyle: GoogleFonts.poppins(),
                                      prefixIcon: Container(
                                        padding: const EdgeInsets.all(12),
                                        child: const Icon(
                                          Icons.flag,
                                          color: Color(0xFF0D47A1),
                                        ),
                                      ),
                                      suffixIcon: Icon(
                                        Icons.search,
                                        color: Colors.grey[400],
                                        size: 20,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF0D47A1),
                                          width: 2,
                                        ),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 1.5,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: _tempatBerangkat == null
                                          ? Colors.grey[100]
                                          : Colors.white,
                                      hintText: _tempatBerangkat == null
                                          ? 'Pilih tempat berangkat dulu'
                                          : 'Ketuk untuk pilih tujuan',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Pilih tujuan';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Optional pickup point (based on departure city)
                              if (_tempatBerangkat != null)
                                _buildLocationTile(
                                  title: 'Titik Jemput (opsional)',
                                  subtitle: _pickupAddress ??
                                      'Pilih titik jemput di peta',
                                  onTap: () => _pickLocation(isPickup: true),
                                ),
                              if (_tempatBerangkat != null)
                                const SizedBox(height: 12),
                              // Optional drop-off point (based on destination city)
                              if (_tujuan != null)
                                _buildLocationTile(
                                  title: 'Titik Antar (opsional)',
                                  subtitle: _dropoffAddress ??
                                      'Pilih titik antar di peta',
                                  onTap: () => _pickLocation(isPickup: false),
                                ),
                              if (_tujuan != null) const SizedBox(height: 20),
                              // Date Picker Field
                              TextFormField(
                                controller: _dateController,
                                readOnly: true,
                                onTap: _selectDate,
                                decoration: InputDecoration(
                                  labelText: 'Tanggal Keberangkatan',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  hintText: 'Pilih tanggal keberangkatan',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Pilih tanggal keberangkatan';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _searchTravel,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search),
                                    SizedBox(width: 8),
                                    Text(
                                      'Cari Travel',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Hasil Pencarian PO
                      if (_tempatBerangkat != null && _tujuan != null) ...[
                        const SizedBox(height: 24),
                        if (provider.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (provider.poList.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.search_off_rounded,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Tidak ada PO ditemukan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.route_rounded,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_tempatBerangkatDisplay ?? _tempatBerangkat} → ${_tujuanDisplay ?? _tujuan}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Coba ubah pencarian atau pilih rute lain',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF0D47A1),
                                  const Color(0xFF1976D2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF0D47A1).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.search_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Hasil Pencarian',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${provider.poList.length} PO',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0D47A1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.route_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${_tempatBerangkatDisplay ?? _tempatBerangkat} → ${_tujuanDisplay ?? _tujuan}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ...provider.poList.map((po) => _buildPOCard(po)),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPOCard(POModel po) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 20),
      shadowColor: const Color(0xFF0D47A1).withOpacity(0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFF0D47A1).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFF0D47A1).withOpacity(0.02),
            ],
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PODetailScreen(
                  po: po,
                  from: _tempatBerangkat!,
                  to: _tujuan!,
                  date: _tanggalBerangkat,
                  pickupCoord: _pickupCoord,
                  pickupAddress: _pickupAddress,
                  dropoffCoord: _dropoffCoord,
                  dropoffAddress: _dropoffAddress,
                  departureProvinceId:
                      _selectedProvince?.id, // NEW: Track province
                  departureLocation: _pickupCoord, // NEW: Track user location
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D47A1).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            po.nama,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D47A1),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            po.companyCode,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D47A1).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF0D47A1),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Info Pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoPill(
                      icon: Icons.directions_bus_rounded,
                      label: '${po.vehicleCount} Kendaraan',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                      ),
                    ),
                    _buildInfoPill(
                      icon: Icons.star_rounded,
                      label: 'Premium',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Contact Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF0D47A1).withOpacity(0.1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildContactRow(
                        icon: Icons.phone_rounded,
                        text: po.phone,
                        color: const Color(0xFF1976D2),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: Colors.grey[200],
                      ),
                      const SizedBox(height: 12),
                      _buildContactRow(
                        icon: Icons.location_on_rounded,
                        text: po.address,
                        color: const Color(0xFFE53935),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Action Button
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D47A1).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PODetailScreen(
                            po: po,
                            from: _tempatBerangkat!,
                            to: _tujuan!,
                            date: _tanggalBerangkat,
                            pickupCoord: _pickupCoord,
                            pickupAddress: _pickupAddress,
                            dropoffCoord: _dropoffCoord,
                            dropoffAddress: _dropoffAddress,
                            departureProvinceId:
                                _selectedProvince?.id, // NEW: Track province
                            departureLocation:
                                _pickupCoord, // NEW: Track user location
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Lihat Jadwal & Harga',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationTile(
      {required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.place, color: Color(0xFF0D47A1)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.map_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
