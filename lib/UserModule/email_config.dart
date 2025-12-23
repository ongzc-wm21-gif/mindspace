// Email Configuration File
// 
// IMPORTANT: For production, store these values securely (environment variables, secure storage, etc.)
// DO NOT commit sensitive credentials to version control
//
// Gmail Setup Instructions:
// 1. Enable 2-Step Verification on your Google account
// 2. Generate an App Password: https://myaccount.google.com/apppasswords
// 3. Use the generated App Password (not your regular password) below
//
// For other email providers, adjust the SMTP settings accordingly:
// - Outlook/Hotmail: smtp-mail.outlook.com, port 587
// - Yahoo: smtp.mail.yahoo.com, port 587
// - Custom SMTP: Check with your email provider

class EmailConfig {
  // SMTP Server Settings
  static const String smtpHost = 'smtp.gmail.com';
  static const int smtpPort = 587;
  
  // Email Credentials (CHANGE THESE)
  static const String smtpUsername = 'ongzc-wm21@student.tarc.edu.my';
  static const String smtpPassword = 'ctri lamm gibc nraq'; // Gmail App Password
  static const String fromEmail = 'ongzc-wm21@student.tarc.edu.my';
  static const String fromName = 'CalmMind';

  // Email Settings
  static const bool useSSL = false;
  static const bool allowInsecure = true; // Set to false in production with proper SSL

  // OTP Settings
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 10;
}

