import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;

  String _fullImageUrl(String relativeOrAbsoluteUrl) {
    final apiBase = ChatService.baseUrl;
    final base = apiBase.endsWith('/api')
        ? apiBase.substring(0, apiBase.length - 4)
        : apiBase;

    if (relativeOrAbsoluteUrl.startsWith('http')) return relativeOrAbsoluteUrl;
    return '$base$relativeOrAbsoluteUrl';
  }

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    setState(() => _isLoading = true);

    try {
      final rooms = await _chatService.getChatRooms();
      setState(() {
        _chatRooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chat rooms: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pesan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadChatRooms,
                  child: ListView.separated(
                    itemCount: _chatRooms.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final room = _chatRooms[index];
                      return _buildChatTile(room);
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
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada percakapan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Percakapan akan muncul saat Anda melakukan booking',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> room) {
    final bookingType = room['booking_type'] ?? '';
    final driverName = room['driver_name'] ?? 'Driver';
    final driverPhoto = room['driver_photo'];
    final lastMessage = room['last_message_text'] ?? '';
    final lastMessageAt = room['last_message_at'];
    final unreadCount = room['customer_unread_count'] ?? 0;
    final status = room['status'] ?? 'active';

    // Get icon based on booking type
    IconData icon;
    Color iconColor;
    String subtitle;

    switch (bookingType) {
      case 'delivery':
        icon = Icons.local_shipping;
        iconColor = const Color(0xFF4CAF50);
        subtitle = 'Antar Paket';
        break;
      case 'ride':
        icon = Icons.motorcycle;
        iconColor = const Color(0xFF2196F3);
        subtitle = 'Rute Ride';
        break;
      case 'food':
        icon = Icons.restaurant;
        iconColor = const Color(0xFFFF5722);
        subtitle = 'Rute Food';
        break;
      case 'cargo':
        icon = Icons.airport_shuttle;
        iconColor = const Color(0xFFFF9800);
        subtitle = 'Rute Cargo';
        break;
      default:
        icon = Icons.directions_car;
        iconColor = const Color(0xFF0D47A1);
        subtitle = 'Travel';
    }

    return ListTile(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              bookingId: room['booking_id'].toString(),
              bookingType: bookingType,
              driverName: driverName,
              bookingSubtitle: subtitle,
            ),
          ),
        );
        _loadChatRooms(); // Refresh after returning
      },
      leading: driverPhoto != null && driverPhoto.toString().isNotEmpty
          ? CircleAvatar(
              backgroundColor: Colors.grey[200],
              backgroundImage: NetworkImage(_fullImageUrl(driverPhoto)),
            )
          : CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor),
            ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              driverName,
              style: GoogleFonts.poppins(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            lastMessage,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (lastMessageAt != null)
            Text(
              _chatService.formatMessageTime(lastMessageAt),
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          if (status != 'active')
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Selesai',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
