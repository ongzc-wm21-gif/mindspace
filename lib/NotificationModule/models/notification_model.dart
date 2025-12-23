class NotificationModel {
  final int? id;
  final String userId; // auth_uid from Supabase Auth
  final String title;
  final String message;
  final String type; // 'message', 'reminder', 'info', 'alert'
  final bool isRead;
  final int? relatedId; // ID of related item (e.g., message_id, reminder_id)
  final DateTime createdAt;

  NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type = 'info',
    this.isRead = false,
    this.relatedId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'related_id': relatedId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      type: map['type'] as String? ?? 'info',
      isRead: map['is_read'] as bool? ?? false,
      relatedId: map['related_id'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({
    int? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    int? relatedId,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

