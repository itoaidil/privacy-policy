import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/schedule_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import 'midtrans_payment_screen.dart';

class PaymentScreen extends StatefulWidget {
  final ScheduleModel schedule;
  final List<int> selectedSeats;
  final String from;
  final String to;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final Map<String, double>? pickupCoord;
  final String? pickupAddress;
  final Map<String, double>? dropoffCoord;
  final String? dropoffAddress;

  const PaymentScreen({
    super.key,
    required this.schedule,
    required this.selectedSeats,
    required this.from,
    required this.to,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.pickupCoord,
    this.pickupAddress,
    this.dropoffCoord,
    this.dropoffAddress,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();
  final _paymentService = PaymentService();
  String? _selectedPaymentMethod;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'bca',
      'name': 'Transfer Bank BCA',
      'icon': Icons.account_balance,
      'color': Colors.blue,
      'description': 'Transfer ke rekening BCA',
    },
    {
      'id': 'mandiri',
      'name': 'Transfer Bank Mandiri',
      'icon': Icons.account_balance,
      'color': Colors.orange,
      'description': 'Transfer ke rekening Mandiri',
    },
    {
      'id': 'bri',
      'name': 'Transfer Bank BRI',
      'icon': Icons.account_balance,
      'color': Colors.blue[900],
      'description': 'Transfer ke rekening BRI',
    },
    {
      'id': 'gopay',
      'name': 'GoPay',
      'icon': Icons.phone_android,
      'color': Colors.green,
      'description': 'Bayar dengan GoPay',
    },
    {
      'id': 'ovo',
      'name': 'OVO',
      'icon': Icons.phone_android,
      'color': Colors.purple,
      'description': 'Bayar dengan OVO',
    },
    {
      'id': 'dana',
      'name': 'DANA',
      'icon': Icons.phone_android,
      'color': Colors.blue[400],
      'description': 'Bayar dengan DANA',
    },
    {
      'id': 'qris',
      'name': 'QRIS',
      'icon': Icons.qr_code_scanner,
      'color': Colors.red,
      'description': 'Scan QRIS untuk bayar',
    },
    {
      'id': 'cod',
      'name': 'Bayar di Tempat (COD)',
      'icon': Icons.money,
      'color': Colors.green[700],
      'description': 'Bayar saat naik kendaraan',
    },
  ];

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih metode pembayaran terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create booking via API
      final result = await _apiService.createCustomerBooking(
        customerId: _authService.userId!,
        travelId: widget.schedule.travelId,
        selectedSeats: widget.selectedSeats.map((s) => s.toString()).toList(),
        paymentMethod: _selectedPaymentMethod!,
        totalPrice:
            (widget.schedule.price * widget.selectedSeats.length).toDouble(),
        pickupLocation: widget.from,
        dropoffLocation: widget.to,
        pickupLat: widget.pickupCoord?['lat'],
        pickupLng: widget.pickupCoord?['lng'],
        pickupAddress: widget.pickupAddress,
        dropoffLat: widget.dropoffCoord?['lat'],
        dropoffLng: widget.dropoffCoord?['lng'],
        dropoffAddress: widget.dropoffAddress,
      );

      final bookingId = result['data']['booking_id'];

      // Create Midtrans payment token
      final paymentResult = await _paymentService.createPaymentToken(
        bookingId: bookingId,
        amount: (widget.schedule.price * widget.selectedSeats.length),
        customerName: widget.customerName,
        customerEmail: widget.customerEmail,
        customerPhone: widget.customerPhone,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (paymentResult['success'] == true) {
          // Open Midtrans payment page
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MidtransPaymentScreen(
                paymentUrl: paymentResult['redirect_url'],
                orderId: paymentResult['order_id'],
              ),
            ),
          );

          // Handle payment result
          if (result != null) {
            _handlePaymentResult(result, bookingId);
          }
        } else {
          // Fallback to manual payment instructions
          _showPaymentInstructions(bookingId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                e.toString().replaceAll('Exception: Error: Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentResult(Map<String, dynamic> result, int bookingId) async {
    final status = result['status'];
    final orderId = result['order_id'];

    // Auto-sync payment status dari Midtrans
    if (orderId != null && (status == 'success' || status == 'pending')) {
      try {
        print('🔄 Syncing payment status for order: $orderId');

        final syncResult = await _paymentService.checkPaymentStatus(orderId);

        print('✅ Sync result: $syncResult');

        if (syncResult['success'] == true) {
          final updatedStatus = syncResult['updated'];
          print('📊 Updated status: $updatedStatus');

          if (updatedStatus != null &&
              updatedStatus['payment_status'] == 'paid') {
            _showSuccessDialog(
                bookingId, 'Pembayaran berhasil dan telah dikonfirmasi!');
            return;
          }
        }
      } catch (e) {
        print('⚠️ Error syncing payment status: $e');
      }
    }

    // Fallback ke status dari callback
    if (status == 'success') {
      _showSuccessDialog(bookingId, 'Pembayaran berhasil!');
    } else if (status == 'pending') {
      _showSuccessDialog(bookingId, 'Pembayaran pending, menunggu konfirmasi.');
    } else if (status == 'failed') {
      _showFailedDialog('Pembayaran gagal. Silakan coba lagi.');
    } else if (status == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran dibatalkan'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showSuccessDialog(int bookingId, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Expanded(child: Text('Berhasil!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  const Text('Booking ID',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    'BKG$bookingId',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Tutup dialog
              Navigator.pop(context);
              // Kembali ke Home screen dengan clear semua route di atasnya
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFailedDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Gagal'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentInstructions(int bookingId) {
    final method = _paymentMethods.firstWhere(
      (m) => m['id'] == _selectedPaymentMethod,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Expanded(child: Text('Pemesanan Berhasil!')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking ID',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'BKG$bookingId',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Metode Pembayaran: ${method['name']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_selectedPaymentMethod != 'cod') ...[
                const Text(
                  'Instruksi Pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildPaymentInstructions(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Selesaikan pembayaran dalam 24 jam',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Silakan bayar saat naik kendaraan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tunjukkan Booking ID ini kepada driver',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Close all dialogs and navigate back to home
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    switch (_selectedPaymentMethod) {
      case 'bca':
      case 'mandiri':
      case 'bri':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Transfer ke rekening berikut:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedPaymentMethod == 'bca'
                        ? 'BCA - 1234567890'
                        : _selectedPaymentMethod == 'mandiri'
                            ? 'Mandiri - 0987654321'
                            : 'BRI - 5678901234',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text('a.n. PO ${widget.schedule.poName}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '2. Nominal: ${NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(widget.schedule.price * widget.selectedSeats.length)}',
            ),
            const SizedBox(height: 4),
            const Text('3. Kirim bukti transfer ke WhatsApp PO'),
          ],
        );
      case 'gopay':
      case 'ovo':
      case 'dana':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Buka aplikasi $_selectedPaymentMethod'),
            const Text('2. Scan QR Code atau transfer ke nomor:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '0812-3456-7890',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('3. Kirim screenshot pembayaran ke PO'),
          ],
        );
      case 'qris':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Buka aplikasi pembayaran Anda'),
            const Text('2. Pilih menu Scan QR'),
            const Text('3. Scan QR Code yang ditampilkan'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.qr_code, size: 120),
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.schedule.price * widget.selectedSeats.length;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pembayaran'),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.from} → ${widget.to}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(width: 16),
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kursi',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        Text(
                          widget.selectedSeats.join(', '),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        Text(
                          currencyFormat.format(totalPrice),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Payment methods
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._paymentMethods.map((method) {
                    final isSelected = _selectedPaymentMethod == method['id'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedPaymentMethod = method['id'];
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0D47A1)
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (method['color'] as Color)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  method['icon'] as IconData,
                                  color: method['color'] as Color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      method['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      method['description'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: method['id'],
                                groupValue: _selectedPaymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPaymentMethod = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Bottom button
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Konfirmasi Pembayaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
