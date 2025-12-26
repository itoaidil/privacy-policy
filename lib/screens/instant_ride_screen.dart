import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import '../config/app_config.dart';
import 'map_picker_screen.dart';

class InstantRideScreen extends StatefulWidget {
  const InstantRideScreen({super.key});

  @override
  State<InstantRideScreen> createState() => _InstantRideScreenState();
}

class _InstantRideScreenState extends State<InstantRideScreen> {
  String? _pickupAddress;
  String? _destinationAddress;
  String _selectedVehicle = 'motor';
  Map<String, double>? _pickupCoord; // {lat, lng}
  Map<String, double>? _destinationCoord;
  double? _packageWeightKg;
  double? _distanceKm;
  final TextEditingController _weightController = TextEditingController();
  List<String> _allowedVehicles = ['motor'];

  // Item details
  String? _itemSize; // S, M, L
  String?
      _itemType; // document, food, clothing, electronics, glass, fragile, custom
  String? _itemPhotoUrl;
  bool _deliveryGuarantee = false;

  static const int _testDriverUserId = 12; // TEMP: for end-to-end test

  static const List<String> _itemTypes = [
    'document',
    'food',
    'clothing',
    'electronics',
    'glass',
    'fragile',
    'custom'
  ];

  static const Map<String, String> _itemTypeLabels = {
    'document': '📄 Dokumen',
    'food': '🍔 Makanan',
    'clothing': '👕 Pakaian',
    'electronics': '📱 Elektronik',
    'glass': '🥤 Kaca/Cairan',
    'fragile': '⚠️ Fragile',
    'custom': '📦 Lainnya'
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Antar Paket',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Map Placeholder
          Container(
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Peta akan ditampilkan di sini',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Package Weight Input
                    Text(
                      'Berat Paket (kg)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _weightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Masukkan berat, mis. 0.5',
                        hintStyle: GoogleFonts.poppins(fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        suffixText: 'kg',
                      ),
                      onChanged: (val) {
                        final v = double.tryParse(val.replaceAll(',', '.'));
                        setState(() {
                          _packageWeightKg = v;
                        });
                        _recalculateOptions();
                      },
                    ),
                    const SizedBox(height: 20),

                    // Item Size Selection
                    Text(
                      'Ukuran Paket',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['S', 'M', 'L'].map((size) {
                        final isSelected = _itemSize == size;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _itemSize = size;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey[200],
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                size,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Item Type Selection
                    Text(
                      'Tipe Paket',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _itemTypes.map((type) {
                        final isSelected = _itemType == type;
                        return FilterChip(
                          label: Text(
                            _itemTypeLabels[type] ?? type,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _itemType = selected ? type : null;
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(0xFF4CAF50),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Delivery Guarantee
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            color: const Color(0xFF4CAF50),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery Guarantee',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Asuransi pengiriman hingga Rp 5 juta',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _deliveryGuarantee,
                            onChanged: (value) {
                              setState(() {
                                _deliveryGuarantee = value;
                              });
                            },
                            activeColor: const Color(0xFF4CAF50),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Mau kirim paket?',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pickup Location Input
                    _buildLocationField(
                      icon: Icons.my_location,
                      iconColor: const Color(0xFF4CAF50),
                      label: 'Lokasi Ambil Paket',
                      value: _pickupAddress,
                      onTap: () {
                        _showLocationPicker(isPickup: true);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Destination Input
                    _buildLocationField(
                      icon: Icons.location_on,
                      iconColor: Colors.red,
                      label: 'Lokasi Tujuan',
                      value: _destinationAddress,
                      onTap: () {
                        _showLocationPicker(isPickup: false);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Vehicle Selection
                    Text(
                      'Pilih Kendaraan',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _buildVehicleChips(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Find Driver Button
                    ElevatedButton(
                      onPressed: (_pickupAddress != null &&
                              _destinationAddress != null &&
                              _allowedVehicles.contains(_selectedVehicle))
                          ? _findDriver
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Cari Kurir',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? 'Pilih lokasi',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight:
                          value != null ? FontWeight.w500 : FontWeight.normal,
                      color: value != null ? Colors.black87 : Colors.grey[400],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.search, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleOption(
    String value,
    String emoji,
    String name,
    String price,
  ) {
    final isSelected = _selectedVehicle == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedVehicle = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              price,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLocationPicker({required bool isPickup}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapPickerScreen(
          title: 'Pilih Titik di Peta',
        ),
      ),
    );

    if (result is Map) {
      setState(() {
        final addr = result['address']?.toString();
        final lat = (result['lat'] as num?)?.toDouble();
        final lng = (result['lng'] as num?)?.toDouble();
        if (isPickup) {
          _pickupAddress = addr;
          if (lat != null && lng != null) {
            _pickupCoord = {'lat': lat, 'lng': lng};
          }
        } else {
          _destinationAddress = addr;
          if (lat != null && lng != null) {
            _destinationCoord = {'lat': lat, 'lng': lng};
          }
        }
      });
      _recalculateOptions();
    }
  }

  List<Widget> _buildVehicleChips() {
    // Mapping display for each option
    final items = <Map<String, String>>[];
    for (final v in _allowedVehicles) {
      switch (v) {
        case 'sepeda':
          items.add({
            'value': 'sepeda',
            'emoji': '🚲',
            'name': 'Sepeda',
            'price': 'Rp 8.000'
          });
          break;
        case 'sepatu_roda':
          items.add({
            'value': 'sepatu_roda',
            'emoji': '🛼',
            'name': 'Sepatu Roda',
            'price': 'Rp 7.000'
          });
          break;
        case 'wheels':
          items.add({
            'value': 'wheels',
            'emoji': '🛴',
            'name': 'Wheels',
            'price': 'Rp 9.000'
          });
          break;
        case 'motor':
          items.add({
            'value': 'motor',
            'emoji': '🏍️',
            'name': 'Motor',
            'price': 'Rp 15.000'
          });
          break;
      }
    }

    if (items.isEmpty) {
      return [
        Text(
          'Pilih titik & berat untuk melihat opsi kendaraan',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        )
      ];
    }

    return [
      for (int i = 0; i < items.length; i++) ...[
        _buildVehicleOption(
          items[i]['value']!,
          items[i]['emoji']!,
          items[i]['name']!,
          items[i]['price']!,
        ),
        if (i != items.length - 1) const SizedBox(width: 12),
      ]
    ];
  }

  void _recalculateOptions() {
    // Hitung jarak jika kedua koordinat tersedia
    if (_pickupCoord != null && _destinationCoord != null) {
      _distanceKm = _haversineKm(
        _pickupCoord!['lat']!,
        _pickupCoord!['lng']!,
        _destinationCoord!['lat']!,
        _destinationCoord!['lng']!,
      );
    } else {
      _distanceKm = null;
    }

    final newAllowed = <String>[];

    // Aturan jarak
    if (_distanceKm != null && _distanceKm! > 2.0) {
      // > 2 KM → hanya motor
      newAllowed.add('motor');
    } else {
      // <= 2 KM → motor selalu tersedia
      newAllowed.add('motor');
      // Aturan berat: < 1 KG → tambahkan sepeda, sepatu roda, wheels
      if (_packageWeightKg != null && _packageWeightKg! < 1.0) {
        newAllowed.addAll(['sepeda', 'sepatu_roda', 'wheels']);
      }
    }

    setState(() {
      _allowedVehicles = newAllowed;
      if (!_allowedVehicles.contains(_selectedVehicle)) {
        _selectedVehicle = _allowedVehicles.first;
      }
    });
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in KM
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180.0);

  Future<void> _findDriver() async {
    if (_pickupAddress == null || _destinationAddress == null) return;

    // Map vehicle selection to backend values
    final vehicleType = {
          'sepeda': 'bike',
          'sepatu_roda': 'skateboard',
          'wheels': 'wheels',
          'motor': 'motorcycle',
        }[_selectedVehicle] ??
        _selectedVehicle;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 20),
            Text(
              'Mencari driver...',
              style: GoogleFonts.poppins(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      // Step 1: Create booking
      final bookingUrl =
          Uri.parse('${AppConfig.baseUrl}/api/bookings/delivery/create');

      final bookingPayload = {
        'customer_id': _testDriverUserId,
        'vehicle_type': vehicleType,
        'pickup_address': _pickupAddress,
        'dropoff_address': _destinationAddress,
        'pickup_lat': _pickupCoord?['lat'],
        'pickup_lng': _pickupCoord?['lng'],
        'dropoff_lat': _destinationCoord?['lat'],
        'dropoff_lng': _destinationCoord?['lng'],
        'distance_km': _distanceKm ?? 0,
        'package_weight_kg': _packageWeightKg ?? 0,
        // Item details
        'item_size': _itemSize,
        'item_type': _itemType,
        'item_photo_url': _itemPhotoUrl,
        'delivery_guarantee': _deliveryGuarantee,
      };

      final bookingRes = await http.post(
        bookingUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bookingPayload),
      );

      if (bookingRes.statusCode != 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat booking: ${bookingRes.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final bookingData = jsonDecode(bookingRes.body);
      final bookingId = bookingData['booking_id'];

      // Step 2: Execute wave 1 broadcast
      final broadcastUrl = Uri.parse('${AppConfig.baseUrl}/api/broadcast/wave');

      final broadcastPayload = {
        'booking_id': bookingId,
        'wave': 1, // Wave 1: top 5 drivers
      };

      final broadcastRes = await http.post(
        broadcastUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(broadcastPayload),
      );

      Navigator.pop(context); // Close loading dialog

      if (broadcastRes.statusCode == 200) {
        final waveData = jsonDecode(broadcastRes.body);
        final drivers = waveData['drivers'] as List? ?? [];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${drivers.length} driver sedang mencari...'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal broadcast: ${broadcastRes.statusCode}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Ensure dialog closed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
