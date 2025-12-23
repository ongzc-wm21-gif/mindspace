class UserModel {
  final int? userID;
  final String? authUid; // UUID from Supabase Auth
  final String username;
  final String email;
  final String? phoneNumber;
  // Removed: passwordHash (handled by Supabase Auth)
  final String roleType;
  final String dateJoin;

  UserModel({
    this.userID,
    this.authUid,
    required this.username,
    required this.email,
    this.phoneNumber,
    required this.roleType,
    required this.dateJoin,
  });

  // Convert UserModel to Map for database
  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'auth_uid': authUid,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'roleType': roleType,
      'dateJoin': dateJoin,
    };
  }

  // Create UserModel from Map (from database)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userID: (map['userID'] ?? map['userid']) as int?,
      authUid: (map['auth_uid'] ?? map['authUid']) as String?,
      username: (map['username'] ?? map['Username']) as String,
      email: (map['email'] ?? map['Email']) as String,
      phoneNumber: (map['phoneNumber'] ?? map['phonenumber']) as String?,
      roleType: (map['roleType'] ?? map['roletype']) as String,
      dateJoin: (map['dateJoin'] ?? map['datejoin']) as String,
    );
  }

  // Copy method for updates
  UserModel copyWith({
    int? userID,
    String? authUid,
    String? username,
    String? email,
    String? phoneNumber,
    String? roleType,
    String? dateJoin,
  }) {
    return UserModel(
      userID: userID ?? this.userID,
      authUid: authUid ?? this.authUid,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roleType: roleType ?? this.roleType,
      dateJoin: dateJoin ?? this.dateJoin,
    );
  }
}

