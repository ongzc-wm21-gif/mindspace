import 'dart:math';

class OTPGenerator {
  // Generate a random 6-digit OTP
  static String generateOTP({int length = 6}) {
    final random = Random();
    final otp = StringBuffer();
    
    for (int i = 0; i < length; i++) {
      otp.write(random.nextInt(10));
    }
    
    return otp.toString();
  }

  // Generate OTP with expiry time (default 10 minutes)
  static Map<String, dynamic> generateOTPWithExpiry({
    int length = 6,
    Duration expiryDuration = const Duration(minutes: 10),
  }) {
    final otp = generateOTP(length: length);
    final now = DateTime.now();
    final expiresAt = now.add(expiryDuration);

    return {
      'otp': otp,
      'createdAt': now.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}

