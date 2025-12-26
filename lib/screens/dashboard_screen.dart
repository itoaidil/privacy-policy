import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';
import 'booking_history_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'instant_ride_screen.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  int _unreadNotificationCount = 0;
  final AuthService _authService = AuthService();
  StreamSubscription? _notificationSubscription;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardContent(),
      const BookingHistoryScreen(),
      const ProfileScreen(),
    ];
    _loadUnreadCount();

    // Listen to real-time notifications
    _notificationSubscription =
        NotificationService.onNotificationReceived.listen((message) {
      print('🔔 Real-time notification received in dashboard');
      // Automatically reload unread count when new notification arrives
      _loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final userId = _authService.userId;
    if (userId != null) {
      try {
        final count = await NotificationService.getUnreadCount(userId: userId);
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      } catch (e) {
        print('Error loading unread count: $e');
      }
    }
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                  // Reload unread count after returning from notifications
                  _loadUnreadCount();
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99
                          ? '99+'
                          : _unreadNotificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
                  // Menu Grid (dengan Antar Paket di Row 3)
                  Column(
                    children: [
                      // Row 1: 4 menu pertama
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hantar Pulang
                          _buildSquareMenuCard(
                            context: context,
                            icon: Icons.cottage,
                            iconColor: const Color.fromARGB(255, 48, 74, 112),
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
                      // Row 3: Antar Paket di bawah Hantar Umroh
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSquareMenuCard(
                            context: context,
                            icon: Icons.local_shipping,
                            iconColor: const Color(0xFF4CAF50),
                            title: 'Antar\nPaket',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const InstantRideScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          // Placeholder for future menu
                          Opacity(
                            opacity: 0,
                            child: _buildSquareMenuCard(
                              context: context,
                              icon: Icons.abc,
                              iconColor: Colors.grey,
                              title: '',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 10),
                          Opacity(
                            opacity: 0,
                            child: _buildSquareMenuCard(
                              context: context,
                              icon: Icons.abc,
                              iconColor: Colors.grey,
                              title: '',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 10),
                          Opacity(
                            opacity: 0,
                            child: _buildSquareMenuCard(
                              context: context,
                              icon: Icons.abc,
                              iconColor: Colors.grey,
                              title: '',
                              onTap: () {},
                            ),
                          ),
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

  Widget _buildFeaturedCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              backgroundColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 30),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquareMenuCard({
    required BuildContext context,
    IconData? icon,
    String? iconAsset,
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0D47A1).withOpacity(0.15),
              const Color(0xFF1976D2).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconAsset != null)
              Image.asset(iconAsset, width: 45, height: 45)
            else if (icon != null)
              Icon(icon, size: 45, color: iconColor),
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
