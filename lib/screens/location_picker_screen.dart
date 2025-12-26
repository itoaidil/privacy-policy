import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart'; // Import Location model dari home_screen
import '../config/feature_flags.dart';
import '../config/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationPickerScreen extends StatefulWidget {
  final String title; // "Pilih Tempat Berangkat" atau "Pilih Tujuan"
  final int? provinceId; // Province filter (optional)

  const LocationPickerScreen({
    super.key,
    required this.title,
    this.provinceId,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Location> _locations = [];
  List<Location> _popularLocations = [];
  bool _isLoading = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _loadPopularLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPopularLocations() async {
    setState(() => _isLoading = true);

    try {
      // Load popular locations from ALL provinces
      // No filter - user can search any location in Indonesia
      String url = '${AppConfig.baseUrl}/locations?popular=true';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final locations = (data['data'] as List)
            .map((json) => Location.fromJson(json))
            .toList();

        setState(() => _popularLocations = locations);
      }
    } catch (e) {
      debugPrint('Error loading popular locations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _showResults = false;
        _locations = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Search ALL locations across Indonesia (no province filter)
      // User can book travel from any province regardless of GPS location
      String url = '${AppConfig.baseUrl}/locations?search=$query';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final locations = (data['data'] as List)
            .map((json) => Location.fromJson(json))
            .toList();

        setState(() {
          _locations = locations;
          _showResults = true;
        });
      }
    } catch (e) {
      debugPrint('Error searching locations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildLocationTile(Location location) {
    return ListTile(
      contentPadding: EdgeInsets.only(
        left: location.parentName != null ? 24 : 16,
        right: 16,
        top: 12,
        bottom: 12,
      ),
      leading: location.parentName != null
          ? Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Icon(
                Icons.subdirectory_arrow_right,
                color: Colors.grey[400],
                size: 20,
              ),
            )
          : CircleAvatar(
              radius: 24,
              backgroundColor: location.isPopular
                  ? const Color(0xFFFF6F00).withOpacity(0.1)
                  : const Color(0xFF0D47A1).withOpacity(0.1),
              child: Icon(
                location.type == 'city'
                    ? Icons.location_city
                    : Icons.location_on,
                color: location.isPopular
                    ? const Color(0xFFFF6F00)
                    : const Color(0xFF0D47A1),
                size: 22,
              ),
            ),
      title: Text(
        location.displayName,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: location.isPopular ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: location.parentName != null
          ? Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location.parentName!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: () {
        Navigator.pop(context, location);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: GoogleFonts.poppins(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Cari titik keberangkatan',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 15,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          _searchController.clear();
                          _searchLocations('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                _searchLocations(value);
              },
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showResults
                    ? _locations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada lokasi ditemukan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _locations.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey[200],
                            ),
                            itemBuilder: (context, index) {
                              return _buildLocationTile(_locations[index]);
                            },
                          )
                    : _popularLocations.isEmpty
                        ? const SizedBox.shrink()
                        : ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Pencarian terbaru',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              // TODO: Add recent searches from SharedPreferences

                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 24, 16, 16),
                                child: Text(
                                  'Titik naik favorit',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              ..._popularLocations.map((location) {
                                return _buildLocationTile(location);
                              }),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
