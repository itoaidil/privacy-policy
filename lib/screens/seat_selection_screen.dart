import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/schedule_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'payment_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final ScheduleModel schedule;
  final String from;
  final String to;
  final DateTime? date;
  final Map<String, double>? pickupCoord;
  final String? pickupAddress;
  final Map<String, double>? dropoffCoord;
  final String? dropoffAddress;
  final int? departureProvinceId; // NEW: For tracking
  final Map<String, double>? departureLocation; // NEW: User GPS when searching

  const SeatSelectionScreen({
    super.key,
    required this.schedule,
    required this.from,
    required this.to,
    this.date,
    this.pickupCoord,
    this.pickupAddress,
    this.dropoffCoord,
    this.dropoffAddress,
    this.departureProvinceId, // NEW
    this.departureLocation, // NEW
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  List<int> _bookedSeats = [];
  List<int> _selectedSeats = [];
  bool _isLoading = true;
  String? _errorMessage;
  // UI sizing for seats and gaps
  final double _seatSize = 58;
  final double _seatGap = 24; // gap between left and right columns
  final double _benchGap = 12; // small gap for 3-seat bench

  @override
  void initState() {
    super.initState();
    // Debug log to verify navigation and travelId
    // ignore: avoid_print
    print('SeatSelectionScreen opened for travelId: ' +
        widget.schedule.travelId.toString());
    _loadBookedSeats();
  }

  Future<void> _loadBookedSeats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookedSeats = await _apiService.getBookedSeats(
        widget.schedule.travelId,
      );

      setState(() {
        _bookedSeats = bookedSeats.map((s) => int.tryParse(s) ?? 0).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<List<int?>> _generateSeatLayout() {
    final capacity = widget.schedule.capacity;

    // Layout untuk MPV/Minibus Indonesia (driver di kanan)
    // Formasi: 2-2-3 (7-9 seats) atau 2-2-2-3 (9-11 seats) atau 2-2-2-2-3 (11-13 seats)

    final rows = <List<int?>>[];

    // Baris depan: [1, DRIVER]
    rows.add([1, null]); // null akan dirender sebagai kursi driver di kanan

    // Mulai penomoran berurutan dari 2 hingga "capacity"
    int seatNum = 2;
    int remaining = capacity - 1; // karena kursi 1 sudah dipasang di depan

    // Tambahkan baris 2-kursi sebanyak mungkin, sisakan 3 kursi terakhir jika ada
    while (remaining > 3) {
      rows.add([seatNum, seatNum + 1]);
      seatNum += 2;
      remaining -= 2;
    }

    // Tangani sisa kursi
    if (remaining == 3) {
      rows.add([seatNum, seatNum + 1, seatNum + 2]);
    } else if (remaining == 2) {
      rows.add([seatNum, seatNum + 1]);
    } else if (remaining == 1) {
      rows.add([seatNum]);
    }

    return rows;
  }

  Widget _buildSeat(int? seatNumber) {
    if (seatNumber == null) {
      // Empty space atau driver position
      return Container(
        width: _seatSize,
        height: _seatSize,
        margin: const EdgeInsets.all(4),
      );
    }

    final isBooked = _bookedSeats.contains(seatNumber);
    final isSelected = _selectedSeats.contains(seatNumber);

    Color seatColor;
    IconData seatIcon;

    if (isBooked) {
      seatColor = Colors.grey;
      seatIcon = Icons.event_seat;
    } else if (isSelected) {
      seatColor = const Color(0xFF4CAF50); // Green
      seatIcon = Icons.event_seat;
    } else {
      seatColor = const Color(0xFF0D47A1); // Blue
      seatIcon = Icons.event_seat;
    }

    return GestureDetector(
      onTap: isBooked
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  _selectedSeats.remove(seatNumber);
                } else {
                  _selectedSeats.add(seatNumber);
                }
              });
            },
      child: Container(
        width: _seatSize,
        height: _seatSize,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: seatColor.withOpacity(0.1),
          border: Border.all(color: seatColor, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              seatIcon,
              color: seatColor,
              size: 26,
            ),
            Text(
              '$seatNumber',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: seatColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverSeat() {
    return Container(
      width: _seatSize,
      height: _seatSize,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        border: Border.all(color: Colors.orange, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.person,
            color: Colors.orange,
            size: 26,
          ),
          Text(
            'Driver',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToBooking() {
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 kursi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if user is logged in
    if (!_authService.isLoggedIn) {
      // Show login prompt dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Diperlukan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Silakan login terlebih dahulu untuk melanjutkan pemesanan.'),
              const SizedBox(height: 16),
              Text('Kursi dipilih: ${_selectedSeats.join(", ")}'),
              Text('Jumlah: ${_selectedSeats.length} kursi'),
              const SizedBox(height: 8),
              Text(
                'Total: ${NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(widget.schedule.price * _selectedSeats.length)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to login screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text('Login / Daftar'),
            ),
          ],
        ),
      );
    } else {
      // User is logged in, proceed to payment
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Pemesanan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.schedule.poName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text('${widget.from} → ${widget.to}'),
              Text(widget.schedule.formattedDepartureTime),
              const Divider(height: 24),
              Text('Penumpang: ${_authService.userName}'),
              Text('Kursi: ${_selectedSeats.join(", ")}'),
              Text('Jumlah: ${_selectedSeats.length} kursi'),
              const Divider(height: 24),
              Text(
                'Total: ${NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(widget.schedule.price * _selectedSeats.length)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to payment screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      schedule: widget.schedule,
                      selectedSeats: _selectedSeats,
                      from: widget.from,
                      to: widget.to,
                      customerName: _authService.userName ?? '',
                      customerEmail: _authService.userEmail ?? '',
                      customerPhone: _authService.userPhone ?? '',
                      pickupCoord: widget.pickupCoord,
                      pickupAddress: widget.pickupAddress,
                      dropoffCoord: widget.dropoffCoord,
                      dropoffAddress: widget.dropoffAddress,
                      departureProvinceId: widget.departureProvinceId, // NEW
                      departureLocation: widget.departureLocation, // NEW
                    ),
                  ),
                );
              },
              child: const Text('Lanjut Pembayaran'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pilih Kursi'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D47A1),
                  Color(0xFF1565C0),
                  Color(0xFF1976D2),
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  widget.schedule.poName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.from,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward,
                          color: Colors.white, size: 16),
                    ),
                    const Icon(Icons.flag, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.to,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      widget.schedule.formattedDepartureTime,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Legends
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegend(Colors.orange, 'Driver'),
                _buildLegend(const Color(0xFF0D47A1), 'Tersedia'),
                _buildLegend(const Color(0xFF4CAF50), 'Dipilih'),
                _buildLegend(Colors.grey, 'Terisi'),
              ],
            ),
          ),

          // Seat Layout
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadBookedSeats,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            // Label depan bus
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'DEPAN',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            // Seat layout
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: Column(
                                children: _generateSeatLayout()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final rowIndex = entry.key;
                                  final row = entry.value;

                                  // Build row with added spacing between left/right columns
                                  Widget buildTwoSeatRow(
                                      int? left, int? right) {
                                    final leftWidget =
                                        (rowIndex == 0 && left == null)
                                            ? _buildDriverSeat()
                                            : _buildSeat(left);
                                    final rightWidget =
                                        (rowIndex == 0 && right == null)
                                            ? _buildDriverSeat()
                                            : _buildSeat(right);
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        leftWidget,
                                        SizedBox(width: _seatGap),
                                        rightWidget,
                                      ],
                                    );
                                  }

                                  Widget buildThreeSeatRow(
                                      int? a, int? b, int? c) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildSeat(a),
                                        SizedBox(width: _benchGap),
                                        _buildSeat(b),
                                        SizedBox(width: _benchGap),
                                        _buildSeat(c),
                                      ],
                                    );
                                  }

                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: () {
                                      if (row.length == 2) {
                                        return buildTwoSeatRow(row[0], row[1]);
                                      } else if (row.length == 3) {
                                        return buildThreeSeatRow(
                                            row[0], row[1], row[2]);
                                      } else if (row.length == 1) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [_buildSeat(row[0])],
                                        );
                                      }
                                      // Fallback
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: row.map(_buildSeat).toList(),
                                      );
                                    }(),
                                  );
                                }).toList(),
                              ),
                            ),

                            // Label belakang bus
                            Container(
                              margin: const EdgeInsets.only(top: 20),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'BELAKANG',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
          ),

          // Bottom bar with selected info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedSeats.length} Kursi Dipilih',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedSeats.isEmpty
                                ? 'Pilih kursi Anda'
                                : 'Kursi: ${_selectedSeats.join(", ")}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(
                              widget.schedule.price * _selectedSeats.length,
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _selectedSeats.isEmpty ? null : _proceedToBooking,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: const Text(
                        'Lanjutkan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
