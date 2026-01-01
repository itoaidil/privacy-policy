import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chat_service.dart';
import '../config/api_config.dart';

class ChatRoomScreen extends StatefulWidget {
  final String bookingId;
  final String bookingType;
  final String driverName;
  final String bookingSubtitle;

  const ChatRoomScreen({
    super.key,
    required this.bookingId,
    required this.bookingType,
    required this.driverName,
    required this.bookingSubtitle,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _lastMessageId;

  String _fullImageUrl(String relativeOrAbsoluteUrl) {
    // ApiConfig.baseUrl ends with /api; strip it so static /uploads resolves correctly
    final apiBase = ApiConfig.baseUrl;
    final base = apiBase.endsWith('/api')
        ? apiBase.substring(0, apiBase.length - 4)
        : apiBase;

    if (relativeOrAbsoluteUrl.startsWith('http')) return relativeOrAbsoluteUrl;
    return '$base$relativeOrAbsoluteUrl';
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markAsRead();
    _startPolling();
  }

  @override
  void dispose() {
    _chatService.stopPolling();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _chatService.getMessages(
        bookingId: widget.bookingId,
        bookingType: widget.bookingType,
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startPolling() {
    _chatService.startPolling(
      bookingId: widget.bookingId,
      bookingType: widget.bookingType,
      onNewMessage: (newMessage) {
        final messageId = newMessage['id'].toString();
        if (_lastMessageId != messageId) {
          setState(() {
            // Check if message already exists
            final exists =
                _messages.any((m) => m['id'].toString() == messageId);
            if (!exists) {
              _messages.add(newMessage);
              _lastMessageId = messageId;
            }
          });
          _scrollToBottom();
          _markAsRead();
        }
      },
    );
  }

  Future<void> _markAsRead() async {
    await _chatService.markAsRead(
      bookingId: widget.bookingId,
      bookingType: widget.bookingType,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final message = await _chatService.sendMessage(
        bookingId: widget.bookingId,
        bookingType: widget.bookingType,
        messageText: text,
      );

      if (message != null) {
        setState(() {
          _messages.add(message);
          _lastMessageId = message['id'].toString();
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim pesan')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendImage({bool fromCamera = false}) async {
    final imageFile = await _chatService.pickImage(fromCamera: fromCamera);
    if (imageFile == null) return;

    setState(() => _isSending = true);

    try {
      final message = await _chatService.sendImage(
        bookingId: widget.bookingId,
        bookingType: widget.bookingType,
        imageFile: imageFile,
      );

      if (message != null) {
        setState(() {
          _messages.add(message);
          _lastMessageId = message['id'].toString();
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error sending image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim gambar')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _sendImage(fromCamera: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _sendImage(fromCamera: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.driverName,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.bookingSubtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada pesan\nMulai percakapan dengan driver',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['sender_type'] == 'customer';
    final messageType = message['message_type'] ?? 'text';
    final messageText = message['message_text'];
    final imageUrl = message['image_url'];
    final timestamp = message['created_at'];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF0D47A1) : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (messageType == 'image' && imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _fullImageUrl(imageUrl),
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 150,
                            color: Colors.grey[400],
                            child: const Icon(Icons.broken_image, size: 50),
                          );
                        },
                      ),
                    ),
                  if (messageText != null && messageText.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: messageType == 'image' ? 8 : 0,
                      ),
                      child: Text(
                        messageText,
                        style: GoogleFonts.poppins(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _chatService.formatMessageTime(timestamp),
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image, color: Color(0xFF0D47A1)),
              onPressed: _isSending ? null : _showImagePicker,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                enabled: !_isSending,
              ),
            ),
            const SizedBox(width: 8),
            _isSending
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF0D47A1)),
                    onPressed: _sendMessage,
                  ),
          ],
        ),
      ),
    );
  }
}
