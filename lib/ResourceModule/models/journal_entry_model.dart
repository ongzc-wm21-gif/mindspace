class JournalEntryModel {
  final int? id;
  final String userId; // auth_uid from Supabase Auth
  final String text;
  final DateTime createdAt;

  JournalEntryModel({
    this.id,
    required this.userId,
    required this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory JournalEntryModel.fromMap(Map<String, dynamic> map) {
    return JournalEntryModel(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      text: map['text'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  JournalEntryModel copyWith({
    int? id,
    String? userId,
    String? text,
    DateTime? createdAt,
  }) {
    return JournalEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
