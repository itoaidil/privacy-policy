import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final userId = _authService.userId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final notifications =
          await NotificationService.getNotifications(userId: userId);
      final unreadCount =
          await NotificationService.getUnreadCount(userId: userId);

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _unreadCount = unreadCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = _authService.userId;
    if (userId == null) return;

    final success = await NotificationService.markAllAsRead(userId: userId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua notifikasi ditandai sudah dibaca')),
      );
      _loadNotifications();
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notif) async {
    final userId = _authService.userId;
    if (userId == null) return;

    // Mark as read
    final isUnread = notif['is_read'] == false || notif['is_read'] == 0;
    if (isUnread) {
      await NotificationService.markAsRead(notificationId: notif['id']);
    }

    // TODO: Navigate to detail screen based on notification type
    // For now, just refresh
    _loadNotifications();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'booking_created':
      case 'booking_confirmed':
        return Icons.bookmark;
      case 'booking_cancelled':
        return Icons.cancel;
      case 'payment_success':
        return Icons.payment;
      case 'payment_failed':
        return Icons.error_outline;
      case 'driver_assigned':
      case 'trip_started':
        return Icons.directions_car;
      case 'trip_completed':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'booking_created':
      case 'booking_confirmed':
        return Colors.blue;
      case 'booking_cancelled':
        return Colors.red;
      case 'payment_success':
        return Colors.green;
      case 'payment_failed':
        return Colors.orange;
      case 'driver_assigned':
      case 'trip_started':
        return const Color(0xFF0D47A1);
      case 'trip_completed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) {
        return 'Baru saja';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} menit yang lalu';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} jam yang lalu';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} hari yang lalu';
      } else {
        return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Tandai semua sudah dibaca',
              onPressed: _markAllAsRead,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return _buildNotificationItem(notif);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada notifikasi',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi Anda akan muncul di sini',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notif) {
    final isUnread = notif['is_read'] == false || notif['is_read'] == 0;
    final type = notif['type'] ?? 'general';
    final iconColor = _getColorForType(type);

    return InkWell(
      onTap: () => _handleNotificationTap(notif),
      child: Container(
        color: isUnread ? Colors.blue.withOpacity(0.08) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(type),
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif['title'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w400,
                            color: isUnread ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif['body'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isUnread ? Colors.black87 : Colors.grey[600],
                      height: 1.4,
                      fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notif['created_at'] ?? ''),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
