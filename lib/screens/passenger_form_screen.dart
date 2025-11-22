import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/schedule_model.dart';

class PassengerFormScreen extends StatefulWidget {
  final ScheduleModel schedule;
  final List<int> selectedSeats;
  final String from;
  final String to;
  final DateTime? date;

  const PassengerFormScreen({
    super.key,
    required this.schedule,
    required this.selectedSeats,
    required this.from,
    required this.to,
    this.date,
  });

  @override
  State<PassengerFormScreen> createState() => _PassengerFormScreenState();
}

class _PassengerFormScreenState extends State<PassengerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _passengers = [];
  int _currentPassengerIndex = 0;

  // Form controllers for current passenger
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize passenger list
    for (int i = 0; i < widget.selectedSeats.length; i++) {
      _passengers.add({
        'seat_number': widget.selectedSeats[i],
        'name': '',
        'phone': '',
        'email': '',
        'address': '',
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadPassengerData() {
    final passenger = _passengers[_currentPassengerIndex];
    _nameController.text = passenger['name'] ?? '';
    _phoneController.text = passenger['phone'] ?? '';
    _emailController.text = passenger['email'] ?? '';
    _addressController.text = passenger['address'] ?? '';
  }

  void _saveCurrentPassenger() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _passengers[_currentPassengerIndex] = {
          'seat_number': widget.selectedSeats[_currentPassengerIndex],
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
        };
      });
    }
  }

  void _nextPassenger() {
    if (_formKey.currentState!.validate()) {
      _saveCurrentPassenger();

      if (_currentPassengerIndex < widget.selectedSeats.length - 1) {
        setState(() {
          _currentPassengerIndex++;
          _loadPassengerData();
        });
      }
    }
  }

  void _previousPassenger() {
    _saveCurrentPassenger();

    if (_currentPassengerIndex > 0) {
      setState(() {
        _currentPassengerIndex--;
        _loadPassengerData();
      });
    }
  }

  void _proceedToPayment() {
    if (_formKey.currentState!.validate()) {
      _saveCurrentPassenger();

      // Check if all passengers have complete data
      bool allComplete = true;
      for (var passenger in _passengers) {
        if (passenger['name']?.isEmpty ?? true) {
          allComplete = false;
          break;
        }
      }

      if (!allComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lengkapi data semua penumpang terlebih dahulu'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // TODO: Navigate to payment/confirmation screen
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Pemesanan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.schedule.poName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${widget.from} → ${widget.to}'),
                Text('${widget.schedule.formattedDepartureTime}'),
                const Divider(height: 24),
                const Text(
                  'Penumpang:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._passengers.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• Kursi ${p['seat_number']}: ${p['name']}'),
                    )),
                const Divider(height: 24),
                Text(
                  'Total: ${NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(widget.schedule.price * widget.selectedSeats.length)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Process booking
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Proses pembayaran akan segera tersedia'),
                  ),
                );
              },
              child: const Text('Bayar Sekarang'),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Data Penumpang'),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      widget.from,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward,
                          color: Colors.white70, size: 14),
                    ),
                    const Icon(Icons.flag, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      widget.to,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Passenger indicator
          if (widget.selectedSeats.length > 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(widget.selectedSeats.length, (index) {
                  final isActive = index == _currentPassengerIndex;
                  final isCompleted =
                      _passengers[index]['name']?.isNotEmpty ?? false;

                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < widget.selectedSeats.length - 1 ? 8 : 0,
                      ),
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF4CAF50)
                            : isActive
                                ? const Color(0xFF0D47A1)
                                : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Passenger & Seat info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D47A1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.event_seat,
                              color: const Color(0xFF0D47A1),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Penumpang ${_currentPassengerIndex + 1} dari ${widget.selectedSeats.length}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kursi Nomor ${widget.selectedSeats[_currentPassengerIndex]}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name field
                    const Text(
                      'Nama Lengkap',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama lengkap',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama harus diisi';
                        }
                        if (value.trim().length < 3) {
                          return 'Nama minimal 3 karakter';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Phone field
                    const Text(
                      'Nomor Telepon',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: '08xxxxxxxxxx',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nomor telepon harus diisi';
                        }
                        if (!RegExp(r'^0[0-9]{9,12}$').hasMatch(value.trim())) {
                          return 'Format nomor tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email field
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'contoh@email.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email harus diisi';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value.trim())) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address field
                    const Text(
                      'Alamat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan alamat lengkap',
                        prefixIcon: const Icon(Icons.home_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Alamat harus diisi';
                        }
                        if (value.trim().length < 10) {
                          return 'Alamat minimal 10 karakter';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 24),

                    // Navigation buttons (for multiple passengers)
                    if (widget.selectedSeats.length > 1)
                      Row(
                        children: [
                          if (_currentPassengerIndex > 0)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _previousPassenger,
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Sebelumnya'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          if (_currentPassengerIndex > 0)
                            const SizedBox(width: 12),
                          if (_currentPassengerIndex <
                              widget.selectedSeats.length - 1)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _nextPassenger,
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Selanjutnya'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom bar
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
                            '${widget.selectedSeats.length} Penumpang',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kursi: ${widget.selectedSeats.join(", ")}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        currencyFormat.format(
                          widget.schedule.price * widget.selectedSeats.length,
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _proceedToPayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Lanjut ke Pembayaran',
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
}
