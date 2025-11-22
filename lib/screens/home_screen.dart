import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/travel_provider.dart';
import '../models/po_model.dart';
import 'po_detail_screen.dart';
import 'map_picker_screen.dart';

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
  String? _tempatBerangkat;
  String? _tujuan;
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

  // Fetch locations dari API
  Future<List<Location>> fetchLocations(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://travel-api-production-23ae.up.railway.app/api/locations?search=$query&limit=30'),
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
    });
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

  void _searchTravel() {
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
                    Color(0xFF0D47A1), // Biru pekat
                    Color(0xFF1565C0), // Biru medium
                    Color(0xFF1976D2), // Biru terang
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Mau Pulang Kemana?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Cari travel terbaik untuk perjalanan Anda',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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
                              TypeAheadField<Location>(
                                controller: _departureController,
                                builder: (context, controller, focusNode) {
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
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

                                                // Close any open keyboards/suggestion overlays
                                                FocusScope.of(context)
                                                    .unfocus();

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
                                          'Ketik atau pilih tempat berangkat',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Pilih tempat berangkat';
                                      }
                                      if (!provider.departureCities
                                          .contains(value)) {
                                        return 'Kota tidak valid';
                                      }
                                      return null;
                                    },
                                  );
                                },
                                suggestionsCallback: (pattern) async {
                                  if (pattern.isEmpty) {
                                    // Show popular locations when empty
                                    return await fetchPopularLocations();
                                  }
                                  // Search locations by pattern
                                  return await fetchLocations(pattern);
                                },
                                emptyBuilder: (context) => Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Tidak ada lokasi ditemukan',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                itemBuilder: (context, location) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[200]!,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: location.isPopular
                                            ? const Color(0xFFFF6F00)
                                                .withOpacity(0.1)
                                            : const Color(0xFF0D47A1)
                                                .withOpacity(0.1),
                                        child: Icon(
                                          location.type == 'city'
                                              ? Icons.location_city
                                              : Icons.location_on,
                                          color: location.isPopular
                                              ? const Color(0xFFFF6F00)
                                              : const Color(0xFF0D47A1),
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        location.displayName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: location.isPopular
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: location.parentName != null
                                          ? Text(
                                              location.type == 'city'
                                                  ? 'Kota'
                                                  : 'Kecamatan',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            )
                                          : null,
                                      trailing: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  );
                                },
                                onSelected: (location) {
                                  setState(() {
                                    _tempatBerangkat = location.displayName;
                                    _departureController.text =
                                        location.displayName;
                                    _tujuan = null;
                                    _destinationController.clear();
                                  });
                                  // Load destinations menggunakan API provider existing
                                  provider.loadDestinationCities(location.name);
                                },
                              ),
                              const SizedBox(height: 20),
                              TypeAheadField<Location>(
                                controller: _destinationController,
                                builder: (context, controller, focusNode) {
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
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
                                          : 'Ketik atau pilih tujuan',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Pilih tujuan';
                                      }
                                      if (!provider.destinationCities
                                          .contains(value)) {
                                        return 'Kota tidak valid';
                                      }
                                      return null;
                                    },
                                  );
                                },
                                suggestionsCallback: (pattern) async {
                                  if (_tempatBerangkat == null) {
                                    return [];
                                  }
                                  if (pattern.isEmpty) {
                                    // Show popular locations when empty
                                    return await fetchPopularLocations();
                                  }
                                  // Search locations by pattern
                                  return await fetchLocations(pattern);
                                },
                                emptyBuilder: (context) => Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Tidak ada lokasi ditemukan',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                itemBuilder: (context, location) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[200]!,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: location.isPopular
                                            ? const Color(0xFFFF6F00)
                                                .withOpacity(0.1)
                                            : const Color(0xFF0D47A1)
                                                .withOpacity(0.1),
                                        child: Icon(
                                          location.type == 'city'
                                              ? Icons.location_city
                                              : Icons.flag,
                                          color: location.isPopular
                                              ? const Color(0xFFFF6F00)
                                              : const Color(0xFF0D47A1),
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        location.displayName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: location.isPopular
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: location.parentName != null
                                          ? Text(
                                              location.type == 'city'
                                                  ? 'Kota'
                                                  : 'Kecamatan',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            )
                                          : null,
                                      trailing: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  );
                                },
                                onSelected: (location) {
                                  setState(() {
                                    _tujuan = location.displayName;
                                    _destinationController.text =
                                        location.displayName;
                                  });
                                },
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
                                        '$_tempatBerangkat → $_tujuan',
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
                                          '$_tempatBerangkat → $_tujuan',
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
