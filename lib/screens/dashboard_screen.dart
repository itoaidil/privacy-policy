import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'booking_history_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardContent(),
      const BookingHistoryScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Booking App'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Belum ada notifikasi')),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF0D47A1),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userName = authService.userFullName ?? 'Pengguna';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'P';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section with Profile
          Container(
            width: double.infinity,
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
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            child: Column(
              children: [
                // Profile Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    userInitial,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D47A1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Halo, $userName!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mau di Hantar kemana hari ini?',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),

          // Menu Cards Section
          Transform.translate(
            offset: const Offset(0, -10),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Menu Grid (10 menu dalam grid 4 per row)
                  Column(
                    children: [
                      // Row 1: 4 menu pertama
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hantar Pulang
                          _buildSquareMenuCard(
                            context: context,
                            icon: Icons.home,
                            iconColor: const Color(0xFF0D47A1),
                            title: 'Hantar\nPulang',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildSquareMenuCard(
                            context: context,
                            icon: Icons.inventory_2,
                            iconColor: const Color(0xFFFF8F00),
                            title: 'Hantar\nBarang',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fitur Hantar Barang segera hadir!',
                                  ),
                                  backgroundColor: Color(0xFFFF8F00),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildSquareMenuCard(
                            context: context,
                            icon: Icons.tour,
                            iconColor: const Color(0xFF8E24AA),
                            title: 'Hantar\nKeliling',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fitur Hantar Keliling segera hadir!',
                                  ),
                                  backgroundColor: Color(0xFF8E24AA),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildSquareMenuCard(
                            context: context,
                            icon: Icons.local_shipping,
                            iconColor: const Color(0xFFE91E63),
                            title: 'Hantar\nCargo',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fitur Hantar Cargo segera hadir!',
                                  ),
                                  backgroundColor: Color(0xFFE91E63),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Row 2: 4 menu berikutnya
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSquareMenuCard(
                            context: context,
                            icon: Icons.mosque,
                            iconColor: const Color(0xFF00BCD4),
                            title: 'Hantar\nUmroh',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fitur Hantar Umroh segera hadir!',
                                  ),
                                  backgroundColor: Color(0xFF00BCD4),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildSquareMenuCard(
                            context: context,
                            icon: Icons.camera_alt,
                            iconColor: const Color(0xFF9C27B0),
                            title: 'Hantar\nFotografi',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fitur Hantar Fotografi segera hadir!',
                                  ),
                                  backgroundColor: Color(0xFF9C27B0),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildSquareMenuCard(
                            context: context,
                            icon: Icons.campaign,
                            iconColor: const Color(0xFFFF5722),
                            title: 'Hantar\nIklan',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fitur Hantar Iklan segera hadir!',
                                  ),
                                  backgroundColor: Color(0xFFFF5722),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildSquareMenuCard(
                            context: context,
                            icon: Icons.directions_car,
                            iconColor: const Color(0xFF607D8B),
                            title: 'Sewa\nMobil',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Fitur Sewa Mobil segera hadir!'),
                                  backgroundColor: Color(0xFF607D8B),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Row 3: Riwayat Booking (sejajar dengan row 1 & 2)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSquareMenuCard(
                            context: context,
                            icon: Icons.receipt_long,
                            iconColor: const Color(0xFF43A047),
                            title: 'Riwayat\nBooking',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BookingHistoryScreen(),
                                ),
                              );
                            },
                          ),
                          // Placeholder untuk menu baru (bisa ditambahkan di sini)
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 220),

                  // Promo Banner (moved to bottom) (moved to bottom)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6F00),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6F00).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.celebration,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Promo Spesial!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Diskon 10% untuk pengguna baru',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildSquareMenuCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1).withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: iconColor),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
