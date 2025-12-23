import 'package:flutter/material.dart';
import 'package:calmmind/database/supabase_service.dart';
import 'package:calmmind/ChatModule/models/message_model.dart';
import 'package:calmmind/UserModule/user_model.dart';
import 'package:calmmind/ChatModule/screens/admin_chat_detail_screen.dart';

class AdminMessagesScreen extends StatefulWidget {
  final UserModel adminUser;

  const AdminMessagesScreen({super.key, required this.adminUser});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  final SupabaseService _dbHelper = SupabaseService.instance;
  List<String> _userIds = [];
  Map<String, UserModel> _userMap = {};
  Map<String, List<MessageModel>> _messagesMap = {};
  Map<String, int> _unreadCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setupRealtimeListener() {
    _dbHelper.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .listen((data) {
      if (mounted) {
        _loadConversations();
      }
    });
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all users who have sent messages
      final userIds = await _dbHelper.getUsersWithMessages();
      
      // Load user details for each user ID
      final userMap = <String, UserModel>{};
      for (final userId in userIds) {
        final user = await _dbHelper.getUserByAuthUid(userId);
        if (user != null) {
          userMap[userId] = user;
        }
      }

      // Load messages for each user
      final messagesMap = <String, List<MessageModel>>{};
      final unreadCounts = <String, int>{};
      
      for (final userId in userIds) {
        final messages = await _dbHelper.getMessagesForUser(userId);
        messagesMap[userId] = messages;
        
        // Count unread messages
        final unreadCount = messages.where((m) => !m.isRead && !m.isFromAdmin).length;
        unreadCounts[userId] = unreadCount;
      }

      setState(() {
        _userIds = userIds;
        _userMap = userMap;
        _messagesMap = messagesMap;
        _unreadCounts = unreadCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }
  }


  String? _searchQuery;

  String _getLastMessagePreview(String userId) {
    final messages = _messagesMap[userId] ?? [];
    if (messages.isEmpty) return 'No messages yet';
    
    // Find the last non-deleted message
    MessageModel? lastMessage;
    for (int i = messages.length - 1; i >= 0; i--) {
      if (!messages[i].isDeleted) {
        lastMessage = messages[i];
        break;
      }
    }
    
    if (lastMessage == null) return 'No messages yet';
    
    if (lastMessage.messageText != null && lastMessage.messageText!.isNotEmpty) {
      return lastMessage.messageText!.length > 40
          ? '${lastMessage.messageText!.substring(0, 40)}...'
          : lastMessage.messageText!;
    } else if (lastMessage.imageUrl != null) {
      return '📷 Image';
    }
    return 'No messages yet';
  }

  DateTime? _getLastMessageTime(String userId) {
    final messages = _messagesMap[userId] ?? [];
    if (messages.isEmpty) return null;
    
    // Find the last non-deleted message
    for (int i = messages.length - 1; i >= 0; i--) {
      if (!messages[i].isDeleted) {
        return messages[i].createdAt;
      }
    }
    return null;
  }

  List<String> get _filteredUserIds {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return _userIds;
    }
    return _userIds.where((userId) {
      final user = _userMap[userId];
      if (user == null) return false;
      final query = _searchQuery!.toLowerCase();
      return user.username.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.message, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Messages',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_unreadCounts.values.fold(0, (sum, count) => sum + count) > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_unreadCounts.values.fold(0, (sum, count) => sum + count)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // Conversations List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading conversations...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _filteredUserIds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery != null && _searchQuery!.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery != null && _searchQuery!.isNotEmpty
                                  ? 'No conversations found'
                                  : 'No conversations yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery != null && _searchQuery!.isNotEmpty
                                  ? 'Try a different search term'
                                  : 'Users will appear here when they send messages',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUserIds.length,
                        itemBuilder: (context, index) {
                          final userId = _filteredUserIds[index];
                          final user = _userMap[userId];
                          final unreadCount = _unreadCounts[userId] ?? 0;
                          final lastMessageTime = _getLastMessageTime(userId);
                          
                          if (user == null) return const SizedBox.shrink();

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminChatDetailScreen(
                                    adminUser: widget.adminUser,
                                    chatUser: user,
                                  ),
                                ),
                              ).then((_) {
                                // Refresh conversations when returning
                                _loadConversations();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.grey[300],
                                    child: Text(
                                      user.username[0].toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // User info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                user.username,
                                                style: TextStyle(
                                                  fontWeight: unreadCount > 0
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (lastMessageTime != null)
                                              Text(
                                                _formatTime(lastMessageTime),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _getLastMessagePreview(userId),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  fontWeight: unreadCount > 0
                                                      ? FontWeight.w500
                                                      : FontWeight.normal,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            if (unreadCount > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '$unreadCount',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
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

