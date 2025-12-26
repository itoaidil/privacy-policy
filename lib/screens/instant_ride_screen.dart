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

  // Recipient details (filled after first confirm)
  RecipientInfo? _recipientInfo;

  static const int _testDriverUserId = 12; // TEMP: for end-to-end test

  // Pricing constants
  static const double _baseFare = 5000;
  static const double _perKmRate = 2000;
  static const double _guaranteeFee = 3000;

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
                      'Pilih Kendaraan (terakhir)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildVehicleSummary(),
                    const SizedBox(height: 24),

                    // Find Driver Button
                    ElevatedButton(
                      onPressed: (_pickupAddress != null &&
                              _destinationAddress != null &&
                              _allowedVehicles.contains(_selectedVehicle))
                          ? () {
                              if (_recipientInfo == null) {
                                _openRecipientForm();
                              } else {
                                _openReviewOrder();
                              }
                            }
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
                        _recipientInfo == null ? 'Confirm' : 'Review Order',
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

  Widget _buildVehicleSummary() {
    final display = {
      'motor': {'emoji': '🏍️', 'name': 'Motor', 'price': 'Rp 15.000'},
      'sepeda': {'emoji': '🚲', 'name': 'Sepeda', 'price': 'Rp 8.000'},
      'sepatu_roda': {
        'emoji': '🛼',
        'name': 'Sepatu Roda',
        'price': 'Rp 7.000'
      },
      'wheels': {'emoji': '🛴', 'name': 'Wheels', 'price': 'Rp 9.000'},
    }[_selectedVehicle];

    if (display == null) {
      return Text(
        'Pilih titik & berat untuk melihat opsi kendaraan',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Text(
            display['emoji']!,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  display['name']!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  display['price']!,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _allowedVehicles.length > 1
                ? () {
                    _cycleVehicle();
                  }
                : null,
            child: Text(
              'Ganti',
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600),
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

  void _cycleVehicle() {
    if (_allowedVehicles.isEmpty) return;
    final currentIndex = _allowedVehicles.indexOf(_selectedVehicle);
    final nextIndex = (currentIndex + 1) % _allowedVehicles.length;
    setState(() {
      _selectedVehicle = _allowedVehicles[nextIndex];
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

  Future<void> _openRecipientForm() async {
    final info = await Navigator.push<RecipientInfo?>(
      context,
      MaterialPageRoute(
        builder: (_) => RecipientFormScreen(
          initialAddress: _destinationAddress,
          initialContactName: _recipientInfo?.contactName,
          initialContactNumber: _recipientInfo?.contactNumber,
          initialFloorUnit: _recipientInfo?.floorUnit,
          initialNote: _recipientInfo?.noteToDriver,
        ),
      ),
    );

    if (info != null) {
      setState(() {
        _recipientInfo = info;
      });
    }
  }

  Future<void> _openReviewOrder() async {
    if (_pickupAddress == null ||
        _destinationAddress == null ||
        _recipientInfo == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewOrderScreen(
          pickupAddress: _pickupAddress!,
          destinationAddress: _destinationAddress!,
          recipient: _recipientInfo!,
          vehicle: _selectedVehicle,
          itemSize: _itemSize,
          itemType: _itemType,
          deliveryGuarantee: _deliveryGuarantee,
          onBook: _simulateBookDelivery,
        ),
      ),
    );
  }

  /// Calculate total fare based on distance and vehicle type
  double _calculateTotalFare(String vehicleType) {
    final distance = _distanceKm ?? 0;
    double baseFare = _baseFare;

    // Vehicle type multiplier
    double multiplier = 1.0;
    if (vehicleType == 'car') {
      multiplier = 1.5;
    } else if (vehicleType == 'truck') {
      multiplier = 2.0;
    }

    double totalFare = baseFare + (distance * _perKmRate * multiplier);

    // Add guarantee fee if selected
    if (_deliveryGuarantee) {
      totalFare += _guaranteeFee;
    }

    return totalFare;
  }

  Future<void> _simulateBookDelivery() async {
    if (_pickupAddress == null ||
        _destinationAddress == null ||
        _recipientInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data tidak lengkap'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
              'Memproses pesanan...',
              style: GoogleFonts.poppins(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      final bookingUrl =
          Uri.parse('${AppConfig.baseUrl}/bookings/delivery/create');

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
        'total_fare': _calculateTotalFare(vehicleType),
        // Item details
        'item_size': _itemSize,
        'item_type': _itemType,
        'item_photo_url': _itemPhotoUrl,
        'delivery_guarantee': _deliveryGuarantee,
        'guarantee_fee': _deliveryGuarantee ? _guaranteeFee : 0,
        // Recipient details
        'recipient_name': _recipientInfo!.contactName,
        'recipient_phone': _recipientInfo!.contactNumber,
        'recipient_address_detail': _recipientInfo!.floorUnit,
        'recipient_note_to_driver': _recipientInfo!.noteToDriver,
      };

      final bookingRes = await http.post(
        bookingUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bookingPayload),
      );

      Navigator.pop(context); // Close loading dialog

      if (bookingRes.statusCode == 201) {
        final bookingData = jsonDecode(bookingRes.body);
        final bookingId = bookingData['booking_id'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesanan berhasil dibuat! ID: $bookingId'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );

        // Go back to main screen
        Navigator.pop(context); // Close review order
        Navigator.pop(context); // Close instant ride
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat pesanan: ${bookingRes.statusCode}'),
            backgroundColor: Colors.red,
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

class RecipientInfo {
  final String address;
  final String? floorUnit;
  final String contactName;
  final String contactNumber;
  final String? noteToDriver;
  final bool savePlace;

  RecipientInfo({
    required this.address,
    required this.contactName,
    required this.contactNumber,
    this.floorUnit,
    this.noteToDriver,
    this.savePlace = false,
  });
}

class RecipientFormScreen extends StatefulWidget {
  final String? initialAddress;
  final String? initialFloorUnit;
  final String? initialContactName;
  final String? initialContactNumber;
  final String? initialNote;

  const RecipientFormScreen({
    super.key,
    this.initialAddress,
    this.initialFloorUnit,
    this.initialContactName,
    this.initialContactNumber,
    this.initialNote,
  });

  @override
  State<RecipientFormScreen> createState() => _RecipientFormScreenState();
}

class _RecipientFormScreenState extends State<RecipientFormScreen> {
  late TextEditingController _addressController;
  late TextEditingController _floorUnitController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactNumberController;
  late TextEditingController _noteController;
  bool _savePlace = false;

  @override
  void initState() {
    super.initState();
    _addressController =
        TextEditingController(text: widget.initialAddress ?? '');
    _floorUnitController =
        TextEditingController(text: widget.initialFloorUnit ?? '');
    _contactNameController =
        TextEditingController(text: widget.initialContactName ?? '');
    _contactNumberController =
        TextEditingController(text: widget.initialContactNumber ?? '');
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _addressController.dispose();
    _floorUnitController.dispose();
    _contactNameController.dispose();
    _contactNumberController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recipient',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Address *'),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              readOnly: true,
              decoration: _inputDecoration(hint: 'Alamat tujuan').copyWith(
                suffixIcon: const Icon(Icons.lock, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 14),
            _buildLabel('Floor and unit no.'),
            const SizedBox(height: 6),
            TextField(
              controller: _floorUnitController,
              decoration: _inputDecoration(hint: 'Tambah detail lantai/unit'),
              maxLength: 120,
            ),
            const SizedBox(height: 4),
            _buildLabel('Contact name *'),
            const SizedBox(height: 6),
            TextField(
              controller: _contactNameController,
              decoration: _inputDecoration(hint: 'Nama penerima'),
            ),
            const SizedBox(height: 14),
            _buildLabel('Contact number *'),
            const SizedBox(height: 6),
            TextField(
              controller: _contactNumberController,
              decoration: _inputDecoration(hint: 'Nomor HP penerima'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _buildLabel('Note to driver'),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              decoration: _inputDecoration(hint: 'Tambahkan catatan'),
              maxLength: 120,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _savePlace,
                  onChanged: (v) {
                    setState(() {
                      _savePlace = v ?? false;
                    });
                  },
                ),
                Text(
                  'Save this place',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  void _onConfirm() {
    if (_addressController.text.isEmpty ||
        _contactNameController.text.isEmpty ||
        _contactNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Address, contact name, dan nomor HP wajib diisi')),
      );
      return;
    }

    Navigator.pop(
      context,
      RecipientInfo(
        address: _addressController.text,
        floorUnit: _floorUnitController.text.isNotEmpty
            ? _floorUnitController.text
            : null,
        contactName: _contactNameController.text,
        contactNumber: _contactNumberController.text,
        noteToDriver:
            _noteController.text.isNotEmpty ? _noteController.text : null,
        savePlace: _savePlace,
      ),
    );
  }
}

class ReviewOrderScreen extends StatelessWidget {
  final String pickupAddress;
  final String destinationAddress;
  final RecipientInfo recipient;
  final String vehicle;
  final String? itemSize;
  final String? itemType;
  final bool deliveryGuarantee;
  final Future<void> Function() onBook;

  const ReviewOrderScreen({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.recipient,
    required this.vehicle,
    required this.onBook,
    this.itemSize,
    this.itemType,
    this.deliveryGuarantee = false,
  });

  @override
  Widget build(BuildContext context) {
    final vehicleLabel = {
          'motor': 'Motor',
          'sepeda': 'Sepeda',
          'sepatu_roda': 'Sepatu Roda',
          'wheels': 'Wheels',
        }[vehicle] ??
        vehicle;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Review Order',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle('Delivery details'),
                _detailTile('Sender', pickupAddress),
                _detailTile(
                  'Recipient',
                  '${recipient.contactName} • ${recipient.contactNumber}\n${recipient.address}${recipient.floorUnit != null ? '\n${recipient.floorUnit}' : ''}',
                ),
                const SizedBox(height: 16),
                _sectionTitle('Options'),
                _detailTile('Kendaraan', vehicleLabel),
                _detailTile(
                  'Item',
                  '${itemSize ?? '-'} • ${itemType ?? 'Paket'}${deliveryGuarantee ? ' • Delivery Guarantee' : ''}',
                ),
                const SizedBox(height: 16),
                _sectionTitle('Payment details'),
                _detailTile('Metode', 'Bayar di tempat / COD (mock)'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total (mock)',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Rp 12.500',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Book delivery',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _detailTile(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }
}
