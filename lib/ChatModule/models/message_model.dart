class MessageModel {
  final int? id;
  final String userId; // auth_uid from Supabase Auth
  final String? adminId; // auth_uid of admin (null if not assigned)
  final String? messageText; // null if image-only
  final String? imageUrl; // null if text-only, stores Supabase Storage path
  final bool isFromAdmin; // true if admin sent, false if user sent
  final bool isRead; // true if message has been read
  final DateTime createdAt;
  final DateTime? deletedAt; // null if not deleted, timestamp if recalled/deleted

  MessageModel({
    this.id,
    required this.userId,
    this.adminId,
    this.messageText,
    this.imageUrl,
    required this.isFromAdmin,
    this.isRead = false,
    DateTime? createdAt,
    this.deletedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'admin_id': adminId,
      'message_text': messageText,
      'image_url': imageUrl,
      'is_from_admin': isFromAdmin,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      adminId: map['admin_id'] as String?,
      messageText: map['message_text'] as String?,
      imageUrl: map['image_url'] as String?,
      isFromAdmin: map['is_from_admin'] as bool,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
    );
  }

  MessageModel copyWith({
    int? id,
    String? userId,
    String? adminId,
    String? messageText,
    String? imageUrl,
    bool? isFromAdmin,
    bool? isRead,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      adminId: adminId ?? this.adminId,
      messageText: messageText ?? this.messageText,
      imageUrl: imageUrl ?? this.imageUrl,
      isFromAdmin: isFromAdmin ?? this.isFromAdmin,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // Helper to check if message has content
  bool get hasContent => messageText != null && messageText!.isNotEmpty || imageUrl != null && imageUrl!.isNotEmpty;
}

