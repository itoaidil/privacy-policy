import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  MapController? _mapController;

  DriverLocation? _driverLocation;
  TravelTracking? _travelStatus;
  List<PickupQueue> _pickupQueue = [];
  WeatherCondition? _weather;

  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];

  StreamSubscription? _driverLocationSub;
  StreamSubscription? _travelStatusSub;
  StreamSubscription? _pickupQueueSub;

  bool _isLoading = true;
  String? _error;
  bool _showOtherPassengers = true;
  bool _showPolylines = true;

  // ETA calculations
  Map<int, int> _etaMinutes = {}; // booking_id -> ETA in minutes

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
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    try {
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
        _updateMarkers();
        _updatePolylines();
      }
    });
  }

  void _calculateETAs() {
    if (_driverLocation == null) return;

    final driverPos =
        LatLng(_driverLocation!.latitude, _driverLocation!.longitude);
    final distance = const Distance();

    for (var pickup in _pickupQueue) {
      final pickupPos = LatLng(pickup.pickupLatitude, pickup.pickupLongitude);
      final distanceKm =
          distance.as(LengthUnit.Kilometer, driverPos, pickupPos);

      // Assume average speed of 40 km/h
      final etaMinutes = ((distanceKm / 40) * 60).round();
      _etaMinutes[pickup.bookingId] = etaMinutes;
    }
  }

  void _checkProximityNotifications() {
    if (_driverLocation == null) return;

    final driverPos =
        LatLng(_driverLocation!.latitude, _driverLocation!.longitude);
    final distance = const Distance();

    for (var pickup in _pickupQueue) {
      if (pickup.bookingId == widget.bookingId &&
          pickup.status == 'pending') {
        final pickupPos = LatLng(pickup.pickupLatitude, pickup.pickupLongitude);
        final distanceMeters =
            distance.as(LengthUnit.Meter, driverPos, pickupPos);

        if (distanceMeters <= 500) {
          _showProximityNotification(distanceMeters.round());
        }
      }
    }
  }

  void _showProximityNotification(int meters) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Driver sudah dekat! Sekitar $meters meter dari lokasi Anda'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _updateMarkers() {
    _markers.clear();

    // Driver marker
    if (_driverLocation != null && _mapController != null) {
      _markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(_driverLocation!.latitude, _driverLocation!.longitude),
          child: const Icon(
            Icons.local_shipping,
            color: Colors.blue,
            size: 40.0,
          ),
        ),
      );
    }

    // Pickup points markers
    if (_showOtherPassengers) {
      for (var pickup in _pickupQueue) {
        final isMyPickup = pickup.bookingId == widget.bookingId;
        _markers.add(
          Marker(
            width: 60.0,
            height: 60.0,
            point: LatLng(pickup.pickupLatitude, pickup.pickupLongitude),
            child: Icon(
              Icons.location_on,
              color: isMyPickup ? Colors.green : Colors.red,
              size: 40.0,
            ),
          ),
        );
      }
    } else {
      // Show only current user's pickup point
      final myPickup = _pickupQueue.firstWhere(
        (p) => p.bookingId == widget.bookingId,
        orElse: () => _pickupQueue.first,
      );
      _markers.add(
        Marker(
          width: 60.0,
          height: 60.0,
          point: LatLng(myPickup.pickupLatitude, myPickup.pickupLongitude),
          child: const Icon(
            Icons.location_on,
            color: Colors.green,
            size: 40.0,
          ),
        ),
      );
    }
  }

  void _updatePolylines() {
    _polylines.clear();

    if (!_showPolylines || _driverLocation == null) return;

    final driverPos =
        LatLng(_driverLocation!.latitude, _driverLocation!.longitude);

    for (var pickup in _pickupQueue) {
      if (_showOtherPassengers || pickup.bookingId == widget.bookingId) {
        final pickupPos = LatLng(pickup.pickupLatitude, pickup.pickupLongitude);
        _polylines.add(
          Polyline(
            points: [driverPos, pickupPos],
            strokeWidth: 3.0,
            color: pickup.bookingId == widget.bookingId
                ? Colors.green.withOpacity(0.7)
                : Colors.blue.withOpacity(0.5),
          ),
        );
      }
    }
  }

  void _moveCameraToDriver() {
    if (_driverLocation != null && _mapController != null) {
      _mapController!.move(
        LatLng(_driverLocation!.latitude, _driverLocation!.longitude),
        14.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Tracking'),
          backgroundColor: const Color(0xFF1976D2),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Tracking'),
          backgroundColor: const Color(0xFF1976D2),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _initializeTracking();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: const Color(0xFF1976D2),
        actions: [
          IconButton(
            icon: Icon(_showPolylines ? Icons.route : Icons.route_outlined),
            onPressed: () {
              setState(() {
                _showPolylines = !_showPolylines;
                _updatePolylines();
              });
            },
            tooltip: 'Toggle Rute',
          ),
          IconButton(
            icon: Icon(_showOtherPassengers ? Icons.groups : Icons.person),
            onPressed: () {
              setState(() {
                _showOtherPassengers = !_showOtherPassengers;
                _updateMarkers();
                _updatePolylines();
              });
            },
            tooltip: 'Toggle Penumpang Lain',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveCameraToDriver,
            tooltip: 'Pusat ke Driver',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController ??= MapController(),
            options: MapOptions(
              initialCenter: _driverLocation != null
                  ? LatLng(
                      _driverLocation!.latitude, _driverLocation!.longitude)
                  : const LatLng(-0.9471, 100.4172),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.travel_booking_app',
              ),
              PolylineLayer(
                polylines: _polylines,
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),

          // Info Cards
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Status: ${_travelStatus?.status ?? "Unknown"}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (_weather != null) ...[
                          const SizedBox(height: 8),
                          Text('Cuaca: ${_weather!.weatherMain}'),
                          Text('Suhu: ${_weather!.temperature}°C'),
                        ],
                      ],
                    ),
                  ),
                ),

                // ETA Card for current user
                if (_etaMinutes[widget.bookingId] != null)
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'ETA ke lokasi Anda: ${_etaMinutes[widget.bookingId]} menit',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Pickup Queue List (bottom)
          if (_pickupQueue.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                child: ExpansionTile(
                  title: Text('Urutan Penjemputan (${_pickupQueue.length})'),
                  children: _pickupQueue.map((pickup) {
                    final isMyPickup = pickup.bookingId == widget.bookingId;
                    final eta = _etaMinutes[pickup.bookingId];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isMyPickup ? Colors.green : Colors.grey,
                        child: Text('${pickup.queuePosition}'),
                      ),
                      title: Text(
                        isMyPickup ? 'Anda' : 'Penumpang ${pickup.queuePosition}',
                        style: TextStyle(
                          fontWeight:
                              isMyPickup ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        'Status: ${pickup.status}',
                      ),
                      trailing: eta != null
                          ? Text(
                              '$eta mnt',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            )
                          : null,
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
