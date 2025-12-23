class ReminderModel {
  final int? id;
  final String userId; // auth_uid from Supabase Auth
  final String title;
  final String? description;
  final DateTime reminderTime;
  final bool isRecurring;
  final String? recurrenceType; // 'daily', 'weekly', 'monthly', 'yearly', or null
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReminderModel({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.reminderTime,
    this.isRecurring = false,
    this.recurrenceType,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'reminder_time': reminderTime.toIso8601String(),
      'is_recurring': isRecurring,
      'recurrence_type': recurrenceType,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      reminderTime: map['reminder_time'] != null
          ? DateTime.parse(map['reminder_time'] as String)
          : DateTime.now(),
      isRecurring: map['is_recurring'] as bool? ?? false,
      recurrenceType: map['recurrence_type'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  ReminderModel copyWith({
    int? id,
    String? userId,
    String? title,
    String? description,
    DateTime? reminderTime,
    bool? isRecurring,
    String? recurrenceType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper to format reminder time
  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDate = DateTime(reminderTime.year, reminderTime.month, reminderTime.day);

    if (reminderDate == today) {
      return 'Today at ${_formatTime(reminderTime)}';
    } else if (reminderDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow at ${_formatTime(reminderTime)}';
    } else {
      return '${reminderTime.day}/${reminderTime.month}/${reminderTime.year} at ${_formatTime(reminderTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

