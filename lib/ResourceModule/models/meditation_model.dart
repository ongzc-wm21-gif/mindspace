enum MediaType { video, audio }
enum MeditationCategory { Sleep, Focus, Anxiety }

class MeditationModel {
  final int? id;
  final String title;
  final Duration duration;
  final MeditationCategory category;
  final String mediaPath;
  final MediaType mediaType;
  final DateTime createdAt;
  bool isFavorited;

  MeditationModel({
    this.id,
    required this.title,
    required this.duration,
    required this.category,
    required this.mediaPath,
    required this.mediaType,
    DateTime? createdAt,
    this.isFavorited = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'duration': duration.inSeconds,
      'category': category.name,
      'media_path': mediaPath,
      'media_type': mediaType.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MeditationModel.fromMap(Map<String, dynamic> map) {
    return MeditationModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      duration: Duration(seconds: map['duration'] as int),
      category: MeditationCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => MeditationCategory.Sleep,
      ),
      mediaPath: map['media_path'] as String,
      mediaType: MediaType.values.firstWhere(
        (e) => e.name == map['media_type'],
        orElse: () => MediaType.audio,
      ),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      isFavorited: false, // Will be set separately from favorites table
    );
  }

  MeditationModel copyWith({
    int? id,
    String? title,
    Duration? duration,
    MeditationCategory? category,
    String? mediaPath,
    MediaType? mediaType,
    DateTime? createdAt,
    bool? isFavorited,
  }) {
    return MeditationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      mediaPath: mediaPath ?? this.mediaPath,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }
}
