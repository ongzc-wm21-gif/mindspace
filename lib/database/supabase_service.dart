import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:calmmind/UserModule/user_model.dart';
import 'package:calmmind/UserModule/otp_model.dart';
import 'package:calmmind/MoodTrackingModule/models/mood_model.dart';
import 'package:calmmind/MoodTrackingModule/models/habit_model.dart';
import 'package:calmmind/MoodTrackingModule/models/phq9_model.dart';
import 'package:calmmind/MoodTrackingModule/models/daily_record_model.dart';
import 'package:calmmind/ResourceModule/models/event_model.dart';
import 'package:calmmind/ResourceModule/models/meditation_model.dart';
import 'package:calmmind/ResourceModule/models/journal_entry_model.dart';
import 'package:calmmind/ChatModule/models/message_model.dart';

/// Supabase Service - Uses Supabase Authentication
/// All database operations now use auth.uid() for user identification
class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  SupabaseService._init();

  SupabaseClient get client => Supabase.instance.client;

  // Get current authenticated user's UUID
  String? get currentUserId => client.auth.currentUser?.id;

  // ========== USER OPERATIONS ==========

  /// Get user by Supabase Auth UID
  Future<UserModel?> getUserByAuthUid(String authUid) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('auth_uid', authUid)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromMap(response);
    } catch (e) {
      print('Error getting user by auth UID: $e');
      return null;
    }
  }

  /// Get current user profile
  Future<UserModel?> getCurrentUser() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return getUserByAuthUid(uid);
  }

  /// Insert user profile (used after Supabase Auth signup)
  /// This creates the profile in the users table
  Future<void> insertUserProfile(UserModel user) async {
    try {
      await client.from('users').insert({
        'auth_uid': user.authUid,
        'username': user.username,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'roleType': user.roleType,
        'dateJoin': user.dateJoin,
      }).select();
      
      print('✅ Profile created successfully');
    } catch (e) {
      print('❌ Error inserting user profile: $e');
      print('Error type: ${e.runtimeType}');
      print('Error string: ${e.toString()}');
      
      // If it's a duplicate key error, the trigger might have already created it
      if (e.toString().contains('duplicate') || 
          e.toString().contains('unique') ||
          e.toString().contains('already exists')) {
        print('ℹ️ Profile might already exist (created by trigger)');
        return; // Don't throw, just return
      }
      
      // If it's an RLS policy error, provide helpful message
      if (e.toString().contains('policy') || 
          e.toString().contains('permission') ||
          e.toString().contains('RLS') ||
          e.toString().contains('row-level security') ||
          e.toString().contains('new row violates')) {
        print('🚨 RLS policy error!');
        print('Current user ID: ${client.auth.currentUser?.id}');
        print('Trying to insert auth_uid: ${user.authUid}');
        throw Exception('Profile creation blocked by RLS. Error: ${e.toString()}');
      }
      
      // Re-throw with full error details for debugging
      throw Exception('Failed to create profile: ${e.toString()}');
    }
  }

  /// Get user by email (for admin purposes)
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('email', email)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromMap(response);
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(int userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('userID', userId)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromMap(response);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  /// Get all users (for admin purposes)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await client
          .from('users')
          .select()
          .order('dateJoin', ascending: false);

      return (response as List).map((map) => UserModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting all users: $e');
      print('Error type: ${e.runtimeType}');
      print('Error string: ${e.toString()}');
      
      // If it's an RLS policy error, provide helpful message
      if (e.toString().contains('policy') || 
          e.toString().contains('permission') ||
          e.toString().contains('RLS') ||
          e.toString().contains('row-level security')) {
        print('🚨 RLS policy error - Admin cannot see all users!');
        print('Current user ID: ${client.auth.currentUser?.id}');
        throw Exception('Admin access blocked by RLS. Error: ${e.toString()}');
      }
      
      rethrow;
    }
  }

  /// Update user profile
  Future<int> updateUser(UserModel user) async {
    try {
      final response = await client
          .from('users')
          .update({
            'username': user.username,
            'email': user.email,
            'phoneNumber': user.phoneNumber,
            'roleType': user.roleType,
          })
          .eq('auth_uid', user.authUid!)
          .select('userID')
          .single();

      return response['userID'] as int;
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  /// Delete user (admin only - deletes from users table, auth user deletion handled by Supabase)
  Future<int> deleteUser(String authUid) async {
    try {
      await client.from('users').delete().eq('auth_uid', authUid);
      // Note: Deleting from auth.users will cascade delete the profile
      return 0;
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final response = await client
          .from('users')
          .select('userID')
          .eq('email', email)
          .limit(1)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  /// Check if username exists
  Future<bool> usernameExists(String username) async {
    try {
      final response = await client
          .from('users')
          .select('userID')
          .eq('username', username)
          .limit(1)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  // ========== OTP OPERATIONS ==========

  /// Insert OTP
  Future<int> insertOTP(OTPModel otp) async {
    try {
      final response = await client.from('otps').insert({
        'email': otp.email,
        'otpCode': otp.otpCode,
        'createdAt': otp.createdAt,
        'expiresAt': otp.expiresAt,
        'isUsed': otp.isUsed ? 1 : 0,
      }).select('id').single();

      return response['id'] as int;
    } catch (e) {
      print('Error inserting OTP: $e');
      rethrow;
    }
  }

  /// Get valid OTP by email and code
  Future<OTPModel?> getValidOTP(String email, String otpCode) async {
    try {
      final response = await client
          .from('otps')
          .select()
          .eq('email', email)
          .eq('otpCode', otpCode)
          .eq('isUsed', 0)
          .order('createdAt', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final otp = OTPModel.fromMap(response);
      // Check if expired
      if (otp.isValid) {
        return otp;
      }
      return null;
    } catch (e) {
      print('Error getting valid OTP: $e');
      return null;
    }
  }

  /// Mark OTP as used
  Future<int> markOTPAsUsed(int otpId) async {
    try {
      final response = await client
          .from('otps')
          .update({'isUsed': 1})
          .eq('id', otpId)
          .select('id')
          .single();

      return response['id'] as int;
    } catch (e) {
      print('Error marking OTP as used: $e');
      rethrow;
    }
  }

  /// Delete expired OTPs (cleanup)
  Future<int> deleteExpiredOTPs() async {
    try {
      final now = DateTime.now().toIso8601String();
      await client.from('otps').delete().lt('expiresAt', now);
      return 0; // Supabase doesn't return count, so return 0
    } catch (e) {
      print('Error deleting expired OTPs: $e');
      return 0;
    }
  }

  /// Get latest OTP for email (for resend functionality)
  Future<OTPModel?> getLatestOTPForEmail(String email) async {
    try {
      final response = await client
          .from('otps')
          .select()
          .eq('email', email)
          .order('createdAt', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return OTPModel.fromMap(response);
    } catch (e) {
      print('Error getting latest OTP: $e');
      return null;
    }
  }

  // ========== MOOD TRACKING OPERATIONS ==========

  // ================= MOODS =================
  Future<void> insertMood(Mood mood) async {
    try {
      await client.from('moods').insert({
        'auth_uid': currentUserId, // RLS will verify this
        'name': mood.name,
        'emoji': mood.emoji,
        'timestamp': mood.timestamp.toIso8601String(),
      });
    } catch (e) {
      print('Error inserting mood: $e');
      rethrow;
    }
  }

  Future<List<Mood>> getMoods() async {
    try {
      final response = await client
          .from('moods')
          .select()
          .order('timestamp', ascending: false);

      return (response as List).map((map) {
        return Mood(
          name: map['name'] as String,
          emoji: map['emoji'] as String,
          timestamp: DateTime.parse(map['timestamp'] as String),
        );
      }).toList();
    } catch (e) {
      print('Error getting moods: $e');
      return [];
    }
  }

  // ================= HABITS =================
  Future<void> insertHabit(Habit habit) async {
    try {
      await client.from('habits').insert({
        'auth_uid': currentUserId, // RLS will verify this
        'name': habit.name,
        'isCompleted': habit.isCompleted ? 1 : 0,
        'streak': habit.streak,
        'lastCompleted': habit.lastCompleted.toIso8601String(),
      });
    } catch (e) {
      print('Error inserting habit: $e');
      rethrow;
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      await client.from('habits').update({
        'isCompleted': habit.isCompleted ? 1 : 0,
        'streak': habit.streak,
        'lastCompleted': habit.lastCompleted.toIso8601String(),
      }).eq('name', habit.name);
    } catch (e) {
      print('Error updating habit: $e');
      rethrow;
    }
  }

  Future<void> deleteHabit(String name) async {
    try {
      await client.from('habits').delete().eq('name', name);
    } catch (e) {
      print('Error deleting habit: $e');
      rethrow;
    }
  }

  Future<List<Habit>> getHabits() async {
    try {
      final response = await client.from('habits').select();

      return (response as List).map((map) {
        return Habit(
          name: map['name'] as String,
          isCompleted: (map['isCompleted'] as int) == 1,
          streak: map['streak'] as int,
          lastCompleted: DateTime.parse(map['lastCompleted'] as String),
        );
      }).toList();
    } catch (e) {
      print('Error getting habits: $e');
      return [];
    }
  }

  // ================= DAILY RECORDS =================
  Future<void> upsertDailyRecord(DailyRecord record) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.date);
      await client.from('daily_records').upsert({
        'auth_uid': currentUserId, // RLS will verify this
        'date': dateKey,
        'stressLevel': record.stressLevel,
        'sleepQuality': record.sleepQuality,
        'energyLevel': record.energyLevel,
      });
    } catch (e) {
      print('Error upserting daily record: $e');
      rethrow;
    }
  }

  Future<List<DailyRecord>> getDailyRecords() async {
    try {
      final response = await client
          .from('daily_records')
          .select()
          .order('date', ascending: true);

      return (response as List).map((map) {
        return DailyRecord(
          date: DateTime.parse(map['date'] as String),
          stressLevel: (map['stressLevel'] as num).toDouble(),
          sleepQuality: map['sleepQuality'] as int,
          energyLevel: map['energyLevel'] as int,
        );
      }).toList();
    } catch (e) {
      print('Error getting daily records: $e');
      return [];
    }
  }

  // ================= HAPPY MOMENTS =================
  Future<void> insertHappyMoment(String path) async {
    try {
      await client.from('happy_moments').insert({
        'auth_uid': currentUserId, // RLS will verify this
        'path': path,
      });
    } catch (e) {
      print('Error inserting happy moment: $e');
      rethrow;
    }
  }

  Future<List<String>> getHappyMoments() async {
    try {
      final response = await client.from('happy_moments').select('path');

      return (response as List).map((map) => map['path'] as String).toList();
    } catch (e) {
      print('Error getting happy moments: $e');
      return [];
    }
  }

  // ================= PHQ-9 RESULTS =================
  Future<void> insertPHQ9Result(PHQ9Result result) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(result.date);
      await client.from('phq9_results').upsert({
        'auth_uid': currentUserId, // RLS will verify this
        'date': dateKey,
        'score': result.score,
      });
    } catch (e) {
      print('Error inserting PHQ-9 result: $e');
      rethrow;
    }
  }

  Future<List<PHQ9Result>> getPHQ9Results() async {
    try {
      final response = await client
          .from('phq9_results')
          .select()
          .order('date', ascending: true);

      return (response as List).map((map) {
        return PHQ9Result(
          date: DateTime.parse(map['date'] as String),
          score: map['score'] as int,
        );
      }).toList();
    } catch (e) {
      print('Error getting PHQ-9 results: $e');
      return [];
    }
  }

  // ========== RESOURCE MODULE OPERATIONS ==========

  // ========== EVENTS OPERATIONS ==========
  Future<int> insertEvent(EventModel event) async {
    try {
      final response = await client.from('events').insert({
        'title': event.title,
        'location': event.location,
        'date': event.date.toIso8601String(),
      }).select('id').single();

      return response['id'] as int;
    } catch (e) {
      print('Error inserting event: $e');
      rethrow;
    }
  }

  Future<List<EventModel>> getAllEvents() async {
    try {
      final response = await client
          .from('events')
          .select()
          .order('date', ascending: false);

      return (response as List).map((map) => EventModel.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all events: $e');
      return [];
    }
  }

  Future<void> updateEvent(EventModel event) async {
    try {
      if (event.id == null) throw Exception('Event ID is required for update');
      
      await client.from('events').update({
        'title': event.title,
        'location': event.location,
        'date': event.date.toIso8601String(),
      }).eq('id', event.id!);
    } catch (e) {
      print('Error updating event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(int eventId) async {
    try {
      await client.from('events').delete().eq('id', eventId);
    } catch (e) {
      print('Error deleting event: $e');
      rethrow;
    }
  }

  // ========== MEDITATIONS OPERATIONS ==========
  Future<int> insertMeditation(MeditationModel meditation) async {
    try {
      final response = await client.from('meditations').insert({
        'title': meditation.title,
        'duration': meditation.duration.inSeconds,
        'category': meditation.category.name,
        'media_path': meditation.mediaPath,
        'media_type': meditation.mediaType.name,
      }).select('id').single();

      return response['id'] as int;
    } catch (e) {
      print('Error inserting meditation: $e');
      rethrow;
    }
  }

  Future<List<MeditationModel>> getAllMeditations() async {
    try {
      final response = await client
          .from('meditations')
          .select()
          .order('created_at', ascending: false);

      final meditations = (response as List).map((map) => MeditationModel.fromMap(map)).toList();
      
      // Load favorites for current user
      final uid = currentUserId;
      if (uid != null) {
        final favorites = await getFavoriteMeditations(uid);
        final favoriteIds = favorites.map((f) => f['meditation_id'] as int).toSet();
        
        for (var meditation in meditations) {
          if (meditation.id != null && favoriteIds.contains(meditation.id)) {
            meditation.isFavorited = true;
          }
        }
      }
      
      return meditations;
    } catch (e) {
      print('Error getting all meditations: $e');
      return [];
    }
  }

  Future<void> updateMeditation(MeditationModel meditation) async {
    try {
      if (meditation.id == null) throw Exception('Meditation ID is required for update');
      
      await client.from('meditations').update({
        'title': meditation.title,
        'duration': meditation.duration.inSeconds,
        'category': meditation.category.name,
        'media_path': meditation.mediaPath,
        'media_type': meditation.mediaType.name,
      }).eq('id', meditation.id!);
    } catch (e) {
      print('Error updating meditation: $e');
      rethrow;
    }
  }

  Future<void> deleteMeditation(int meditationId) async {
    try {
      await client.from('meditations').delete().eq('id', meditationId);
    } catch (e) {
      print('Error deleting meditation: $e');
      rethrow;
    }
  }

  // ========== FAVORITE MEDITATIONS OPERATIONS ==========
  Future<void> toggleFavoriteMeditation(int meditationId) async {
    try {
      final uid = currentUserId;
      if (uid == null) throw Exception('User not authenticated');

      // Check if already favorited
      final existing = await client
          .from('favorite_meditations')
          .select()
          .eq('user_id', uid)
          .eq('meditation_id', meditationId)
          .maybeSingle();

      if (existing != null) {
        // Remove favorite
        await client
            .from('favorite_meditations')
            .delete()
            .eq('user_id', uid)
            .eq('meditation_id', meditationId);
      } else {
        // Add favorite
        await client.from('favorite_meditations').insert({
          'user_id': uid,
          'meditation_id': meditationId,
        });
      }
    } catch (e) {
      print('Error toggling favorite meditation: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteMeditations(String userId) async {
    try {
      final response = await client
          .from('favorite_meditations')
          .select()
          .eq('user_id', userId);

      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting favorite meditations: $e');
      return [];
    }
  }

  // ========== JOURNAL ENTRIES OPERATIONS ==========
  Future<int> insertJournalEntry(JournalEntryModel entry) async {
    try {
      // Use entry.userId if provided, otherwise use currentUserId
      final uid = entry.userId.isNotEmpty ? entry.userId : (currentUserId ?? '');
      if (uid.isEmpty) throw Exception('User not authenticated');

      final response = await client.from('journal_entries').insert({
        'user_id': uid,
        'text': entry.text,
      }).select('id').single();

      return response['id'] as int;
    } catch (e) {
      print('Error inserting journal entry: $e');
      rethrow;
    }
  }

  Future<List<JournalEntryModel>> getJournalEntries() async {
    try {
      final uid = currentUserId;
      if (uid == null) throw Exception('User not authenticated');

      final response = await client
          .from('journal_entries')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      return (response as List).map((map) => JournalEntryModel.fromMap(map)).toList();
    } catch (e) {
      print('Error getting journal entries: $e');
      return [];
    }
  }

  Future<void> deleteJournalEntry(int entryId) async {
    try {
      await client.from('journal_entries').delete().eq('id', entryId);
    } catch (e) {
      print('Error deleting journal entry: $e');
      rethrow;
    }
  }

  // ========== CHAT MESSAGE OPERATIONS ==========

  /// Send a message (user or admin)
  Future<int> sendMessage(MessageModel message) async {
    try {
      // Create map without id and created_at (let database handle these)
      final map = message.toMap();
      map.remove('id'); // Remove id - database will auto-generate it
      map.remove('created_at'); // Remove created_at - database has default now()
      
      final response = await client
          .from('messages')
          .insert(map)
          .select('id')
          .single();
      return response['id'] as int;
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Get all messages for current user (user view)
  Future<List<MessageModel>> getUserMessages() async {
    try {
      final uid = currentUserId;
      if (uid == null) throw Exception('User not authenticated');

      final response = await client
          .from('messages')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: true);

      return (response as List).map((map) => MessageModel.fromMap(map)).toList();
    } catch (e) {
      print('Error getting user messages: $e');
      return [];
    }
  }

  /// Get all messages for admin (admin view - sees all user conversations)
  Future<List<MessageModel>> getAllMessages() async {
    try {
      final response = await client
          .from('messages')
          .select()
          .order('created_at', ascending: true);

      return (response as List).map((map) => MessageModel.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all messages: $e');
      return [];
    }
  }

  /// Get messages for a specific user (admin view)
  Future<List<MessageModel>> getMessagesForUser(String userId) async {
    try {
      final response = await client
          .from('messages')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      return (response as List).map((map) => MessageModel.fromMap(map)).toList();
    } catch (e) {
      print('Error getting messages for user: $e');
      return [];
    }
  }

  /// Get list of users who have sent messages (for admin inbox)
  Future<List<String>> getUsersWithMessages() async {
    try {
      final response = await client
          .from('messages')
          .select('user_id')
          .order('created_at', ascending: false);

      // Get unique user IDs
      final userIds = (response as List)
          .map((map) => map['user_id'] as String)
          .toSet()
          .toList();
      
      return userIds;
    } catch (e) {
      print('Error getting users with messages: $e');
      return [];
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(int messageId) async {
    try {
      await client
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
    } catch (e) {
      print('Error marking message as read: $e');
      rethrow;
    }
  }

  /// Mark all messages from a user as read (admin)
  Future<void> markUserMessagesAsRead(String userId) async {
    try {
      await client
          .from('messages')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_from_admin', false);
    } catch (e) {
      print('Error marking user messages as read: $e');
      rethrow;
    }
  }

  /// Get unread message count for current user
  Future<int> getUnreadMessageCount() async {
    try {
      final uid = currentUserId;
      if (uid == null) return 0;

      final response = await client
          .from('messages')
          .select('id')
          .eq('user_id', uid)
          .eq('is_read', false)
          .eq('is_from_admin', true);

      return (response as List).length;
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }

  /// Get unread message count for admin (messages from users)
  Future<int> getAdminUnreadMessageCount() async {
    try {
      final response = await client
          .from('messages')
          .select('id')
          .eq('is_read', false)
          .eq('is_from_admin', false);

      return (response as List).length;
    } catch (e) {
      print('Error getting admin unread message count: $e');
      return 0;
    }
  }

  /// Recall/Delete a message (marks as deleted instead of removing)
  Future<void> recallMessage(int messageId) async {
    try {
      await client
          .from('messages')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', messageId);
    } catch (e) {
      print('Error recalling message: $e');
      rethrow;
    }
  }

  /// Delete a message (permanent deletion - kept for admin use if needed)
  Future<void> deleteMessage(int messageId) async {
    try {
      await client
          .from('messages')
          .delete()
          .eq('id', messageId);
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // ========== NOTIFICATIONS ==========

  /// Get all notifications for current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final uid = currentUserId;
      if (uid == null) throw Exception('User not authenticated');

      final response = await client
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting notifications: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final uid = currentUserId;
      if (uid == null) return 0;

      final response = await client
          .from('notifications')
          .select('id')
          .eq('user_id', uid)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final uid = currentUserId;
      if (uid == null) throw Exception('User not authenticated');

      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      await client
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Upload image to Supabase Storage and return URL
  /// Note: This requires proper file handling. For now, returns the file path.
  /// In production, you'll need to implement actual file upload to Supabase Storage.
  Future<String> uploadChatImage(String filePath, String fileName) async {
    try {
      final uid = currentUserId;
      if (uid == null) throw Exception('User not authenticated');

      // Create unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${uid}_$timestamp$fileName';

      // TODO: Implement actual file upload to Supabase Storage
      // For now, return a placeholder path
      // In production, use: await client.storage.from('chat-images').upload(uniqueFileName, fileBytes)
      // Then get public URL: client.storage.from('chat-images').getPublicUrl(uniqueFileName)
      
      return 'chat-images/$uniqueFileName';
    } catch (e) {
      print('Error uploading chat image: $e');
      rethrow;
    }
  }

  // ========== REMINDERS ==========

  /// Create a new reminder
  Future<int> createReminder(Map<String, dynamic> reminderData) async {
    try {
      final uid = currentUserId;
      if (uid == null) throw Exception('User not authenticated');

      reminderData['user_id'] = uid;
      final response = await client
          .from('reminders')
          .insert(reminderData)
          .select('id')
          .single();

      return response['id'] as int;
    } catch (e) {
      print('Error creating reminder: $e');
      rethrow;
    }
  }

  /// Get all reminders for current user
  Future<List<Map<String, dynamic>>> getReminders() async {
    try {
      final uid = currentUserId;
      if (uid == null) throw Exception('User not authenticated');

      final response = await client
          .from('reminders')
          .select()
          .eq('user_id', uid)
          .order('reminder_time', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting reminders: $e');
      rethrow;
    }
  }

  /// Get active reminders for current user
  Future<List<Map<String, dynamic>>> getActiveReminders() async {
    try {
      final uid = currentUserId;
      if (uid == null) throw Exception('User not authenticated');

      final response = await client
          .from('reminders')
          .select()
          .eq('user_id', uid)
          .eq('is_active', true)
          .order('reminder_time', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting active reminders: $e');
      rethrow;
    }
  }

  /// Get next reminder for current user
  Future<Map<String, dynamic>?> getNextReminder() async {
    try {
      final uid = currentUserId;
      if (uid == null) throw Exception('User not authenticated');

      final response = await client
          .from('reminders')
          .select()
          .eq('user_id', uid)
          .eq('is_active', true)
          .gt('reminder_time', DateTime.now().toIso8601String())
          .order('reminder_time', ascending: true)
          .limit(1)
          .maybeSingle();

      return response as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting next reminder: $e');
      return null;
    }
  }

  /// Update reminder
  Future<void> updateReminder(int reminderId, Map<String, dynamic> updates) async {
    try {
      await client
          .from('reminders')
          .update(updates)
          .eq('id', reminderId);
    } catch (e) {
      print('Error updating reminder: $e');
      rethrow;
    }
  }

  /// Delete reminder
  Future<void> deleteReminder(int reminderId) async {
    try {
      await client
          .from('reminders')
          .delete()
          .eq('id', reminderId);
    } catch (e) {
      print('Error deleting reminder: $e');
      rethrow;
    }
  }

  /// Toggle reminder active status
  Future<void> toggleReminderActive(int reminderId, bool isActive) async {
    try {
      await client
          .from('reminders')
          .update({'is_active': isActive})
          .eq('id', reminderId);
    } catch (e) {
      print('Error toggling reminder: $e');
      rethrow;
    }
  }
}

