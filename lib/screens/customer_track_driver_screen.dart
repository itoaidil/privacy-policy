import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomerTrackDriverScreen extends StatefulWidget {
  final int travelId;
  final int bookingId;
  final String origin;
  final String destination;
  final double pickupLat;
  final double pickupLng;

  const CustomerTrackDriverScreen({
    Key? key,
    required this.travelId,
    required this.bookingId,
    required this.origin,
    required this.destination,
    required this.pickupLat,
    required this.pickupLng,
  }) : super(key: key);

  @override
  State<CustomerTrackDriverScreen> createState() =>
      _CustomerTrackDriverScreenState();
}

class _CustomerTrackDriverScreenState extends State<CustomerTrackDriverScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  Timer? _locationTimer;
  double? _driverLat;
  double? _driverLng;
  DateTime? _lastUpdate;
  bool _isLoading = true;
  double? _distanceKm;
  int? _etaMinutes;
  List<LatLng> _routePoints = []; // Untuk menyimpan rute jalan

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startTracking() {
    // Initial load
    _fetchDriverLocation();

    // Auto-refresh every 5 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchDriverLocation();
    });
  }

  Future<void> _fetchDriverLocation() async {
    try {
      final response =
          await _apiService.getDriverLocationByTravel(widget.travelId);

      // Check if success and data exists
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _driverLat = double.tryParse(data['latitude']?.toString() ?? '');
          _driverLng = double.tryParse(data['longitude']?.toString() ?? '');
          _lastUpdate = DateTime.now();
          _isLoading = false;

          // Calculate distance and ETA
          if (_driverLat != null && _driverLng != null) {
            _distanceKm = _calculateDistance(
              _driverLat!,
              _driverLng!,
              widget.pickupLat,
              widget.pickupLng,
            );
            // Assume average speed 40 km/h in city
            _etaMinutes = (_distanceKm! / 40 * 60).ceil();
          }
        });

        // Auto-zoom to show both markers
        if (_driverLat != null && _driverLng != null) {
          _fitBounds();
          _fetchRoute(); // Fetch rute jalan dari OSRM
        }
      } else {
        // Driver belum mulai, tapi tetap tampilkan peta
        setState(() {
          _isLoading = false;
          _driverLat = null;
          _driverLng = null;
          _routePoints = []; // Clear route
        });
      }
    } catch (e) {
      // Error koneksi, tetap tampilkan peta
      setState(() {
        _isLoading = false;
        _driverLat = null;
        _driverLng = null;
        _routePoints = [];
      });
    }
  }

  // Fetch rute mengikuti jalan dari OSRM (Open Source Routing Machine)
  Future<void> _fetchRoute() async {
    if (_driverLat == null || _driverLng == null) return;

    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/$_driverLng,$_driverLat;${widget.pickupLng},${widget.pickupLat}?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates =
              data['routes'][0]['geometry']['coordinates'] as List;

          setState(() {
            _routePoints = coordinates
                .map((coord) => LatLng(coord[1] as double, coord[0] as double))
                .toList();
          });

          // Update jarak dan ETA dari OSRM (lebih akurat)
          final distance = data['routes'][0]['distance'] / 1000; // meter to km
          final duration =
              data['routes'][0]['duration'] / 60; // seconds to minutes

          setState(() {
            _distanceKm = distance;
            _etaMinutes = duration.ceil();
          });
        }
      }
    } catch (e) {
      print('Error fetching route: $e');
      // Fallback ke garis lurus jika routing gagal
      setState(() {
        _routePoints = [];
      });
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Pi/180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  void _fitBounds() {
    if (_driverLat == null || _driverLng == null) return;

    final bounds = LatLngBounds(
      LatLng(_driverLat!, _driverLng!),
      LatLng(widget.pickupLat, widget.pickupLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lacak Driver',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.route, color: Color(0xFF0D47A1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.origin} → ${widget.destination}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_distanceKm != null && _etaMinutes != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'ETA: $_etaMinutes menit',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF0D47A1), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.social_distance,
                                size: 16, color: Color(0xFF0D47A1)),
                            const SizedBox(width: 4),
                            Text(
                              '${_distanceKm!.toStringAsFixed(1)} km',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0D47A1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else if (_driverLat == null && !_isLoading) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pending,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'Menunggu driver memulai perjalanan...',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_lastUpdate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Update terakhir: ${_formatTime(_lastUpdate!)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter:
                              LatLng(widget.pickupLat, widget.pickupLng),
                          initialZoom: 13.0,
                          minZoom: 5.0,
                          maxZoom: 18.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.example.travel_booking_app',
                          ),
                          // Route line from driver to pickup (follows road if available)
                          if (_driverLat != null && _driverLng != null)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _routePoints.isNotEmpty
                                      ? _routePoints // Gunakan rute jalan dari OSRM
                                      : [
                                          // Fallback ke garis lurus jika routing gagal
                                          LatLng(_driverLat!, _driverLng!),
                                          LatLng(widget.pickupLat,
                                              widget.pickupLng),
                                        ],
                                  strokeWidth: 6.0,
                                  color: Colors.blue.shade700,
                                  borderStrokeWidth: 2.0,
                                  borderColor: Colors.white,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              // My pickup location (RED)
                              Marker(
                                point:
                                    LatLng(widget.pickupLat, widget.pickupLng),
                                width: 80,
                                height: 80,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Saya',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ],
                                ),
                              ),
                              // Driver location (BLUE) - only show if available
                              if (_driverLat != null && _driverLng != null)
                                Marker(
                                  point: LatLng(_driverLat!, _driverLng!),
                                  width: 80,
                                  height: 80,
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D47A1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Driver',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D47A1),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0D47A1)
                                                  .withOpacity(0.5),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.local_taxi,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                // Zoom to fit button
                if (_driverLat != null && _driverLng != null)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      heroTag: 'zoom_fit',
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _fitBounds,
                      child: const Icon(
                        Icons.zoom_out_map,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),

                // Refresh button
                Positioned(
                  right: 16,
                  bottom: 72,
                  child: FloatingActionButton(
                    heroTag: 'refresh',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _fetchDriverLocation,
                    child: const Icon(
                      Icons.refresh,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.update,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Posisi driver diperbarui otomatis setiap 5 detik',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 10) {
      return 'Baru saja';
    } else if (diff.inSeconds < 60) {
      return '${diff.inSeconds} detik yang lalu';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit yang lalu';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
