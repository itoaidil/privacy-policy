import 'dart:convert';
import 'dart:math' show cos, sin, sqrt, atan2, pi;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;

class MapPickerScreen extends StatefulWidget {
  final String title;
  final String? initialCity;

  const MapPickerScreen({super.key, required this.title, this.initialCity});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  ll.LatLng _center = ll.LatLng(-6.1754, 106.8272); // Jakarta default
  ll.LatLng? _cityCenter; // Pusat kota untuk validasi radius
  bool _loading = false;
  bool _searching = false;
  String? _address;

  // Radius maksimum dalam kilometer
  static const double _maxRadiusKm = 50.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
      _initFromCity(widget.initialCity!);
    } else {
      _reverseGeocode(_center);
    }
  }

  Future<void> _initFromCity(String city) async {
    setState(() => _loading = true);
    try {
      final loc = await _forwardGeocode('$city, Indonesia');
      if (loc != null) {
        _center = loc;
        _cityCenter = loc; // Simpan pusat kota untuk validasi
      }
      await _reverseGeocode(_center);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Hitung jarak antara dua koordinat dalam kilometer menggunakan Haversine formula
  double _calculateDistance(ll.LatLng point1, ll.LatLng point2) {
    const double earthRadius = 6371; // Radius bumi dalam km

    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final dLat = (point2.latitude - point1.latitude) * pi / 180;
    final dLon = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  bool _isWithinRadius(ll.LatLng point) {
    if (_cityCenter == null)
      return true; // Skip validasi jika tidak ada city center
    final distance = _calculateDistance(_cityCenter!, point);
    return distance <= _maxRadiusKm;
  }

  Future<ll.LatLng?> _forwardGeocode(String query) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&limit=1&q=${Uri.encodeComponent(query)}');
    final res =
        await http.get(url, headers: {'User-Agent': 'travel_booking_app'});
    if (res.statusCode == 200) {
      final list = json.decode(res.body);
      if (list is List && list.isNotEmpty) {
        final item = list.first;
        final lat = double.tryParse(item['lat'].toString());
        final lon = double.tryParse(item['lon'].toString());
        if (lat != null && lon != null) {
          return ll.LatLng(lat, lon);
        }
      }
    }
    return null;
  }

  Future<void> _reverseGeocode(ll.LatLng p) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${p.latitude}&lon=${p.longitude}&addressdetails=1');
    try {
      final res =
          await http.get(url, headers: {'User-Agent': 'travel_booking_app'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) setState(() => _address = data['display_name']);
      }
    } catch (_) {}
  }

  void _onMapMovedEnd() {
    final c = _mapController.center;
    _center = c;
    _reverseGeocode(c);
    if (mounted) setState(() {});
  }

  Future<void> _performSearch() async {
    final raw = _searchCtrl.text.trim();
    if (raw.isEmpty) return;
    setState(() => _searching = true);
    try {
      final biasCity = widget.initialCity?.isNotEmpty == true
          ? ', ${widget.initialCity}'
          : '';
      final query = '$raw$biasCity, Indonesia';
      final loc = await _forwardGeocode(query);
      if (loc != null) {
        _mapController.move(loc, 16);
        _center = loc;
        await _reverseGeocode(loc);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lokasi tidak ditemukan')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mencari lokasi')),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<List<_PlaceSuggestion>> _searchAutocomplete(String input) async {
    final q = input.trim();
    if (q.isEmpty) return [];
    final biasCity =
        widget.initialCity?.isNotEmpty == true ? ', ${widget.initialCity}' : '';
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&limit=8&q='
        '${Uri.encodeComponent('$q$biasCity, Indonesia')}');
    try {
      final res =
          await http.get(url, headers: {'User-Agent': 'travel_booking_app'});
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body);
      if (data is! List) return [];
      return data.map<_PlaceSuggestion>((e) {
        final lat = double.tryParse(e['lat'].toString());
        final lon = double.tryParse(e['lon'].toString());
        final dn = e['display_name']?.toString() ?? '';
        final name = e['name']?.toString() ??
            (e['address']?['road']?.toString() ?? dn.split(',').first);
        return _PlaceSuggestion(
          displayName: dn,
          title: name,
          position:
              (lat != null && lon != null) ? ll.LatLng(lat, lon) : _center,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 14,
                    onMapEvent: (evt) {
                      if (evt is MapEventMoveEnd) {
                        _onMapMovedEnd();
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.travel_booking_app',
                    ),
                  ],
                ),
                const IgnorePointer(
                  child: Center(
                    child:
                        Icon(Icons.location_pin, size: 48, color: Colors.red),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 90,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _address ?? 'Menentukan alamat…',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Validasi radius sebelum return
                        if (!_isWithinRadius(_center)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Titik yang dipilih terlalu jauh dari ${widget.initialCity ?? 'kota'}. '
                                'Maksimal radius $_maxRadiusKm km.',
                              ),
                              backgroundColor: Colors.orange,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).pop({
                          'lat': _center.latitude,
                          'lng': _center.longitude,
                          'address': _address,
                        });
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Pakai Titik Ini'),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: SafeArea(
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: TypeAheadField<_PlaceSuggestion>(
                        controller: _searchCtrl,
                        suggestionsCallback: (pattern) async {
                          setState(() => _searching = true);
                          final items = await _searchAutocomplete(pattern);
                          if (mounted) setState(() => _searching = false);
                          return items;
                        },
                        emptyBuilder: (context) => const SizedBox.shrink(),
                        itemBuilder: (context, item) => ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onSelected: (item) async {
                          _searchCtrl.text = item.displayName;
                          _mapController.move(item.position, 16);
                          _center = item.position;
                          await _reverseGeocode(item.position);
                        },
                        hideOnEmpty: true,
                        builder: (context, controller, focusNode) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _performSearch(),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              hintText:
                                  'Cari alamat / tempat (mis. kos, rumah, mall)',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searching
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.my_location),
                                      tooltip: 'Cari',
                                      onPressed: _performSearch,
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PlaceSuggestion {
  final String title;
  final String displayName;
  final ll.LatLng position;

  _PlaceSuggestion({
    required this.title,
    required this.displayName,
    required this.position,
  });
}
