import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/driver_location.dart';
import '../models/travel_tracking.dart';
import '../models/pickup_queue.dart';
import '../models/weather_condition.dart';
import '../services/tracking_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final int travelId;
  final int driverId;
  final int bookingId;
  final String? token;

  const LiveTrackingScreen({
    Key? key,
    required this.travelId,
    required this.driverId,
    required this.bookingId,
    this.token,
  }) : super(key: key);

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  late TrackingService _trackingService;
  GoogleMapController? _mapController;

  DriverLocation? _driverLocation;
  TravelTracking? _travelStatus;
  List<PickupQueue> _pickupQueue = [];
  WeatherCondition? _weather;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  StreamSubscription? _driverLocationSub;
  StreamSubscription? _travelStatusSub;
  StreamSubscription? _pickupQueueSub;

  bool _isLoading = true;
  String? _error;
  bool _showOtherPassengers = true;
  bool _showPolylines = true;

  // ETA calculations
  Map<int, int> _etaMinutes = {}; // booking_id -> ETA in minutes

  // Notification tracking
  Set<int> _notifiedPickups = {};
  static const double _notificationDistance = 0.5; // 500 meters

  @override
  void initState() {
    super.initState();
    _trackingService = TrackingService(token: widget.token);
    _initializeTracking();
  }

  @override
  void dispose() {
    _driverLocationSub?.cancel();
    _travelStatusSub?.cancel();
    _pickupQueueSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get initial data using travel_id
      final driverLoc =
          await _trackingService.getDriverLocationByTravel(widget.travelId);
      final travelStatus =
          await _trackingService.getLatestTravelStatus(widget.travelId);
      final queue = await _trackingService.getPickupQueue(widget.travelId);

      if (driverLoc != null) {
        final weather = await _trackingService.getWeatherByCoordinates(
          driverLoc.latitude,
          driverLoc.longitude,
        );

        setState(() {
          _driverLocation = driverLoc;
          _travelStatus = travelStatus;
          _pickupQueue = queue;
          _weather = weather;
          _isLoading = false;
        });

        _calculateETAs();
        _updateMarkers();
        _updatePolylines();
        _moveCameraToDriver();
      } else {
        setState(() {
          _error = 'Tidak dapat menemukan lokasi driver';
          _isLoading = false;
        });
      }

      // Start real-time streaming
      _startStreaming();
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  void _startStreaming() {
    // Stream driver location updates
    _driverLocationSub = _trackingService
        .streamDriverLocation(widget.driverId)
        .listen((location) {
      if (location != null && mounted) {
        setState(() {
          _driverLocation = location;
        });
        _calculateETAs();
        _checkProximityNotifications();
        _updateMarkers();
        _updatePolylines();
      }
    });

    // Stream travel status updates
    _travelStatusSub =
        _trackingService.streamTravelStatus(widget.travelId).listen((status) {
      if (status != null && mounted) {
        setState(() {
          _travelStatus = status;
        });
      }
    });

    // Stream pickup queue updates
    _pickupQueueSub =
        _trackingService.streamPickupQueue(widget.travelId).listen((queue) {
      if (mounted) {
        setState(() {
          _pickupQueue = queue;
        });
        _calculateETAs();
        _updateMarkers();
        _updatePolylines();
      }
    });
  }

  void _updateMarkers() {
    _markers.clear();

    // Add driver marker
    if (_driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            _driverLocation!.latitude,
            _driverLocation!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Driver',
            snippet: _driverLocation!.address ?? 'Lokasi Driver',
          ),
        ),
      );
    }

    // Add pickup markers
    for (var pickup in _pickupQueue) {
      final isMyPickup = pickup.bookingId == widget.bookingId;

      // Skip other passengers if filter is enabled
      if (!isMyPickup && !_showOtherPassengers) continue;

      final eta = _etaMinutes[pickup.bookingId];
      final etaText = eta != null ? 'ETA: ${_formatETA(eta)}' : '';

      _markers.add(
        Marker(
          markerId: MarkerId('pickup_${pickup.id}'),
          position: LatLng(
            pickup.pickupLatitude,
            pickup.pickupLongitude,
          ),
          icon: isMyPickup
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: isMyPickup
                ? 'Lokasi Anda'
                : 'Penumpang ${pickup.queuePosition}',
            snippet: '${pickup.distanceDisplay} • $etaText',
          ),
        ),
      );
    }
  }

  void _updatePolylines() {
    _polylines.clear();

    if (!_showPolylines || _driverLocation == null) return;

    // Add polylines from driver to each pickup point
    for (var pickup in _pickupQueue) {
      final isMyPickup = pickup.bookingId == widget.bookingId;

      // Skip other passengers if filter is enabled
      if (!isMyPickup && !_showOtherPassengers) continue;

      // Skip completed pickups
      if (pickup.status == 'completed') continue;

      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_${pickup.id}'),
          points: [
            LatLng(_driverLocation!.latitude, _driverLocation!.longitude),
            LatLng(pickup.pickupLatitude, pickup.pickupLongitude),
          ],
          color: isMyPickup ? Colors.green : Colors.red.withOpacity(0.5),
          width: isMyPickup ? 4 : 2,
          patterns:
              isMyPickup ? [] : [PatternItem.dash(10), PatternItem.gap(5)],
        ),
      );
    }
  }

  void _calculateETAs() {
    if (_driverLocation == null) return;

    _etaMinutes.clear();

    for (var pickup in _pickupQueue) {
      if (pickup.status == 'completed') continue;

      final distance = pickup.distanceFromDriver ?? 0;
      // Assume average speed of 30 km/h in city
      final durationMinutes = ((distance / 30) * 60).ceil();

      // Add queue waiting time (5 minutes per person in queue before them)
      final queueDelay = (pickup.queuePosition - 1) * 5;

      _etaMinutes[pickup.bookingId] = durationMinutes + queueDelay;
    }
  }

  void _checkProximityNotifications() {
    if (_driverLocation == null) return;

    for (var pickup in _pickupQueue) {
      // Only notify for current user's pickup
      if (pickup.bookingId != widget.bookingId) continue;

      // Skip if already notified
      if (_notifiedPickups.contains(pickup.bookingId)) continue;

      // Skip if not waiting
      if (pickup.status != 'waiting') continue;

      final distance = pickup.distanceFromDriver ?? 999;

      if (distance <= _notificationDistance) {
        _notifiedPickups.add(pickup.bookingId);
        _showProximityNotification(pickup);
      }
    }
  }

  void _showProximityNotification(PickupQueue pickup) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Driver sudah dekat! Persiapkan diri Anda.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatETA(int minutes) {
    if (minutes < 1) return 'Tiba sebentar lagi';
    if (minutes < 60) return '$minutes mnt';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours jam $mins mnt';
  }

  void _moveCameraToDriver() {
    if (_mapController != null && _driverLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _driverLocation!.latitude,
              _driverLocation!.longitude,
            ),
            zoom: 14,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showPolylines ? Icons.route : Icons.route_outlined),
            onPressed: () {
              setState(() {
                _showPolylines = !_showPolylines;
                _updatePolylines();
              });
            },
            tooltip: _showPolylines ? 'Sembunyikan Rute' : 'Tampilkan Rute',
          ),
          IconButton(
            icon: Icon(
                _showOtherPassengers ? Icons.people : Icons.people_outline),
            onPressed: () {
              setState(() {
                _showOtherPassengers = !_showOtherPassengers;
                _updateMarkers();
                _updatePolylines();
              });
            },
            tooltip: _showOtherPassengers
                ? 'Sembunyikan Penumpang Lain'
                : 'Tampilkan Semua',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveCameraToDriver,
            tooltip: 'Fokus ke Driver',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeTracking,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeTracking,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Status Bar
                    _buildStatusBar(),

                    // Weather Alert
                    if (_weather != null && _weather!.isDangerous)
                      _buildWeatherAlert(),

                    // Map
                    Expanded(
                      flex: 2,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            _driverLocation?.latitude ?? -0.9471,
                            _driverLocation?.longitude ?? 100.4172,
                          ),
                          zoom: 14,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                      ),
                    ),

                    // Pickup Queue List
                    Expanded(
                      flex: 1,
                      child: _buildPickupQueueList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: _getStatusColor(),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _travelStatus?.statusDisplay ?? 'Menunggu Update',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_weather != null)
                  Text(
                    '${_weather!.weatherIcon} ${_weather!.temperatureDisplay} - ${_weather!.weatherDescription}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_travelStatus?.status) {
      case 'on_the_way':
        return Colors.blue;
      case 'arrived':
        return Colors.orange;
      case 'picked_up':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_travelStatus?.status) {
      case 'on_the_way':
        return Icons.directions_car;
      case 'arrived':
        return Icons.place;
      case 'picked_up':
        return Icons.people;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Widget _buildWeatherAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Peringatan Cuaca: ${_weather!.weatherDescription}. Harap berhati-hati!',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupQueueList() {
    if (_pickupQueue.isEmpty) {
      return const Center(
        child: Text('Tidak ada data antrian penjemputan'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Antrian Penjemputan (${_pickupQueue.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _pickupQueue.length,
              itemBuilder: (context, index) {
                final pickup = _pickupQueue[index];
                final isMyPickup = pickup.bookingId == widget.bookingId;

                return Container(
                  color: isMyPickup ? Colors.green.shade50 : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isMyPickup ? Colors.green : Colors.blue,
                      child: Text(
                        '${pickup.queuePosition}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      isMyPickup ? 'Lokasi Anda' : pickup.pickupLocation,
                      style: TextStyle(
                        fontWeight:
                            isMyPickup ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pickup.distanceDisplay} dari driver • ${pickup.statusDisplay}',
                        ),
                        if (_etaMinutes[pickup.bookingId] != null &&
                            pickup.status != 'completed')
                          Text(
                            'ETA: ${_formatETA(_etaMinutes[pickup.bookingId]!)}',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: isMyPickup
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
