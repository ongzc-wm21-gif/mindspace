class EventModel {
  final int? id;
  final String title;
  final String location;
  final DateTime date;
  final DateTime createdAt;

  EventModel({
    this.id,
    required this.title,
    required this.location,
    required this.date,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      location: map['location'] as String,
      date: DateTime.parse(map['date'] as String),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  EventModel copyWith({
    int? id,
    String? title,
    String? location,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

