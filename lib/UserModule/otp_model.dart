class OTPModel {
  final int? id;
  final String email;
  final String otpCode;
  final String createdAt;
  final String expiresAt;
  final bool isUsed;

  OTPModel({
    this.id,
    required this.email,
    required this.otpCode,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
  });

  // Convert OTPModel to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'otpCode': otpCode,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'isUsed': isUsed ? 1 : 0,
    };
  }

  // Create OTPModel from Map (from database)
  // Handles both Supabase (case-sensitive) and SQLite formats
  factory OTPModel.fromMap(Map<String, dynamic> map) {
    return OTPModel(
      id: map['id'] as int?,
      email: (map['email'] ?? map['Email']) as String,
      otpCode: (map['otpCode'] ?? map['otpcode']) as String,
      createdAt: (map['createdAt'] ?? map['createdat']) as String,
      expiresAt: (map['expiresAt'] ?? map['expiresat']) as String,
      isUsed: ((map['isUsed'] ?? map['isused']) as int) == 1,
    );
  }

  // Check if OTP is expired
  bool get isExpired {
    try {
      final expiryDate = DateTime.parse(expiresAt);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true;
    }
  }

  // Check if OTP is valid (not used and not expired)
  bool get isValid => !isUsed && !isExpired;
}

