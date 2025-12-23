class Mood {
  final String emoji;
  final String name;
  final DateTime timestamp;

  Mood({required this.emoji, required this.name, required this.timestamp});

  Mood copyWith({String? emoji, String? name, DateTime? timestamp}) {
    return Mood(
      emoji: emoji ?? this.emoji,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

