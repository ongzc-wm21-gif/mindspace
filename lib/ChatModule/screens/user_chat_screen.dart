import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:calmmind/database/supabase_service.dart';
import 'package:calmmind/ChatModule/models/message_model.dart';
import 'package:calmmind/UserModule/user_model.dart';

class UserChatScreen extends StatefulWidget {
  final UserModel user;

  const UserChatScreen({super.key, required this.user});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final SupabaseService _dbHelper = SupabaseService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _pendingMessageText; // Track pending message to show loading

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Set up real-time listener for new messages
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupRealtimeListener() {
    _dbHelper.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', widget.user.authUid!)
        .order('created_at', ascending: true)
        .listen((data) {
      if (mounted) {
        final newMessages = (data as List)
            .map((map) => MessageModel.fromMap(map))
            .where((msg) => msg.deletedAt == null) // Filter out deleted messages
            .toList();
        setState(() {
          _messages = newMessages;
          // Clear pending message when real message arrives
          if (_pendingMessageText != null && newMessages.any((msg) => 
              msg.messageText == _pendingMessageText && !msg.isFromAdmin)) {
            _pendingMessageText = null;
          }
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await _dbHelper.getUserMessages();
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
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

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    // Clear input immediately for better UX
    _messageController.clear();

    setState(() {
      _isSending = true;
      _pendingMessageText = text; // Store pending message
    });

    try {
      final message = MessageModel(
        userId: widget.user.authUid!,
        messageText: text,
        isFromAdmin: false,
      );

      // Send message - real-time listener will update UI automatically
      await _dbHelper.sendMessage(message);
      // Pending message will be removed when real message arrives via real-time
    } catch (e) {
      // Restore message text on error
      _messageController.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
        _pendingMessageText = null; // Clear pending message on error
      });
    }
  }

  Future<void> _sendImageMessage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() {
        _isSending = true;
      });

      // Upload image (for now, using file path - in production, upload to Supabase Storage)
      final imageUrl = await _dbHelper.uploadChatImage(
        image.path,
        image.name,
      );

      final message = MessageModel(
        userId: widget.user.authUid!,
        imageUrl: imageUrl,
        isFromAdmin: false,
      );

      // Send message - real-time listener will update UI automatically
      await _dbHelper.sendMessage(message);
      // No need to reload - real-time stream will handle it
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending image: $e')),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat to Admin'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet.\nStart a conversation!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_pendingMessageText != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show pending message at the end if exists
                          if (_pendingMessageText != null && index == _messages.length) {
                            return _buildPendingMessageBubble(_pendingMessageText!);
                          }
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
          ),
          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _isSending ? null : _sendImageMessage,
                  color: const Color(0xFF2196F3),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
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
                    onSubmitted: (_) => _sendTextMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isSending ? null : _sendTextMessage,
                  color: const Color(0xFF2196F3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recallMessage(MessageModel message) async {
    if (message.id == null || message.isDeleted) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recall Message'),
        content: const Text('Are you sure you want to recall this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Recall'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbHelper.recallMessage(message.id!);
        await _loadMessages();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error recalling message: $e')),
          );
        }
      }
    }
  }

  Widget _buildPendingMessageBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3).withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isFromUser = !message.isFromAdmin;
    final alignment = isFromUser ? Alignment.centerRight : Alignment.centerLeft;

    // Show recalled message indicator if deleted
    if (message.isDeleted) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: 12,
          left: isFromUser ? 0 : 60,
          right: isFromUser ? 60 : 0,
        ),
        child: Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.block,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'This message was recalled',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: isFromUser ? () => _recallMessage(message) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isFromUser ? const Color(0xFF2196F3) : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    message.imageUrl!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 50);
                    },
                  ),
                ),
              if (message.messageText != null && message.messageText!.isNotEmpty) ...[
                if (message.imageUrl != null) const SizedBox(height: 8),
                Text(
                  message.messageText!,
                  style: TextStyle(
                    color: isFromUser ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isFromUser ? Colors.white70 : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                  if (isFromUser) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

