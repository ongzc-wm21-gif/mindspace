import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'user_model.dart';
import 'profile_screen.dart';
import '../MoodTrackingModule/mood_tracker_screen.dart';
import '../MoodTrackingModule/models/mood_model.dart';
import '../ResourceModule/screens/resource_screen.dart';
import '../ChatModule/screens/user_chat_screen.dart';
import '../NotificationModule/screens/notifications_screen.dart';
import '../RemindersModule/screens/reminders_list_screen.dart';
import '../RemindersModule/screens/add_edit_reminder_screen.dart';
import '../RemindersModule/models/reminder_model.dart';
import '../database/supabase_service.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final UserModel? user;
  
  const HomePage({super.key, this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // Home is selected by default
  final SupabaseService _dbHelper = SupabaseService.instance;
  int _notificationCount = 0;
  ReminderModel? _nextReminder;
  String? _selectedMoodEmoji; // Track selected mood emoji
  
  // Encouragement messages for each mood
  final Map<String, String> _encouragementMessages = {
    '😄': 'Your joy is contagious! Keep spreading that positive energy and remember to share your happiness with others.',
    '🙂': 'You\'re doing great! Take a moment to appreciate the good things in your day, no matter how small.',
    '😐': 'It\'s okay to feel neutral. Every day is different, and tomorrow brings new opportunities for growth.',
    '😰': 'Feeling anxious is valid. Take deep breaths, you\'re stronger than you think. This feeling will pass.',
    '😢': 'It\'s okay to feel sad. Your feelings are valid. Remember, you don\'t have to face this alone.',
    '😠': 'Anger is a natural emotion. Take a moment to breathe and process. You have the strength to handle this.',
  };

  bool _isGuideExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
    _setupNotificationListener();
    _loadNextReminder();
    _loadTodayMood();
  }

  Future<void> _loadTodayMood() async {
    try {
      final todayMood = await _dbHelper.getTodayMood();
      if (mounted && todayMood != null) {
        setState(() {
          _selectedMoodEmoji = todayMood.emoji;
        });
      }
    } catch (e) {
      print('Error loading today mood: $e');
    }
  }

  Future<void> _loadNextReminder() async {
    try {
      final data = await _dbHelper.getNextReminder();
      if (mounted) {
        setState(() {
          _nextReminder = data != null ? ReminderModel.fromMap(data) : null;
        });
      }
    } catch (e) {
      print('Error loading next reminder: $e');
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final count = await _dbHelper.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  void _setupNotificationListener() {
    if (widget.user?.authUid != null) {
      _dbHelper.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .listen((data) {
        if (mounted) {
          // Filter notifications for current user and unread
          final filtered = (data as List).where((item) {
            return item['user_id'] == widget.user!.authUid &&
                   item['is_read'] == false;
          }).toList();
          setState(() {
            _notificationCount = filtered.length;
          });
        }
      });
    }
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const MoodTrackerScreen();
      case 1:
        return _buildHomeContent();
      case 2:
        return _buildResourcesContent();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SafeArea(
        child: Column(
          children: [
            // Blue Header
            _buildHeader(),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    _buildWelcomeSection(),
                    const SizedBox(height: 16),
                    // Daily Tip Section
                    _buildDailyTipSection(),
                    const SizedBox(height: 16),
                    // Reminders Section
                    _buildRemindersSection(),
                    const SizedBox(height: 16),
                    // Need Help Section
                    _buildNeedHelpSection(),
                    const SizedBox(height: 16),
                    // Crisis & Emergency Section
                    _buildCrisisSection(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildResourcesContent() {
    return ResourceScreen(user: widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _getCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF2196F3), // Blue
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Row(
            children: [
              Icon(Icons.eco, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text(
                'MindSpace',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              if (widget.user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(user: widget.user!),
                  ),
                );
              }
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(
                        user: widget.user!,
                      ),
                    ),
                  ).then((_) {
                    // Refresh notification count when returning
                    _loadNotificationCount();
                  });
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _notificationCount > 99 ? '99+' : '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final displayName = widget.user?.username ?? 'Guest';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👋', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'Welcome, $displayName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'How are you feeling today?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMoodEmoji('😄', 'Very Happy'),
              _buildMoodEmoji('🙂', 'Happy'),
              _buildMoodEmoji('😐', 'Neutral'),
              _buildMoodEmoji('😰', 'Anxious'),
              _buildMoodEmoji('😢', 'Sad'),
              _buildMoodEmoji('😠', 'Angry'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodEmoji(String emoji, String label) {
    final isSelected = _selectedMoodEmoji == emoji;
    return GestureDetector(
      onTap: () async {
        try {
          // If clicking the same emoji, don't do anything (or you could deselect it)
          if (isSelected) {
            // Optionally allow deselecting by clicking again
            // For now, we'll just update it again
          }
          
          // Create mood object
          final mood = Mood(
            emoji: emoji,
            name: label,
            timestamp: DateTime.now(),
          );
          
          // Upsert mood (update if exists today, otherwise insert)
          await _dbHelper.upsertMood(mood);
          
          // Update selected mood
          setState(() {
            _selectedMoodEmoji = emoji;
          });
          
          // Show feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isSelected ? 'Mood updated: $label' : 'Mood recorded: $label'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          print('Error saving mood: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving mood: $e'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: const Color(0xFF2196F3), width: 3)
                  : null,
              color: isSelected ? const Color(0xFF2196F3).withOpacity(0.1) : null,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Reminders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.lightBlue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: _nextReminder != null
                ? Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF2196F3), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Next: ${_nextReminder!.title} at ${DateFormat('HH:mm').format(_nextReminder!.reminderTime)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Row(
                    children: [
                      Icon(Icons.access_time, color: Color(0xFF2196F3), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'No upcoming reminders',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RemindersListScreen(),
                      ),
                    ).then((_) => _loadNextReminder());
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2196F3),
                    side: const BorderSide(color: Color(0xFF2196F3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Manage Reminders',
                    style: TextStyle(color: Color(0xFF2196F3)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddEditReminderScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadNextReminder();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Reminder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTipSection() {
    // Get encouragement message based on selected mood, or default message
    final tipMessage = _selectedMoodEmoji != null && _encouragementMessages.containsKey(_selectedMoodEmoji!)
        ? _encouragementMessages[_selectedMoodEmoji!]!
        : 'Slow progress is still progress. Keep breathing.';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.push_pin, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                _selectedMoodEmoji != null ? 'Your Encouragement' : 'Daily Tip',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tipMessage,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWellbeingStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bar_chart, size: 20),
            SizedBox(width: 8),
            Text(
              'Your Wellbeing Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Mood trend', Icons.show_chart, Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Minutes meditated', Icons.timer, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Streaks', Icons.local_fire_department, Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNeedHelpSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF6A5AE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _isGuideExpanded = !_isGuideExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.rocket_launch, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'MindSpace Guide',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _isGuideExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Quick tour of what you can do in the app',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGuideRow(
                          icon: Icons.mood,
                          title: 'Mood Check',
                          description:
                              'Tap an emoji to log how you feel and get an encouragement tip that adapts to your mood.',
                        ),
                        const SizedBox(height: 10),
                        _buildGuideRow(
                          icon: Icons.notifications_active,
                          title: 'Reminders',
                          description:
                              'Set reminders for self-care, sessions, or tasks. View the next one at a glance on Home.',
                        ),
                        const SizedBox(height: 10),
                        _buildGuideRow(
                          icon: Icons.message,
                          title: 'Chat to Admin',
                          description:
                              'Reach out anytime. Send text or images, and recall messages if needed.',
                        ),
                        const SizedBox(height: 10),
                        _buildGuideRow(
                          icon: Icons.campaign,
                          title: 'Notifications',
                          description:
                              'Stay updated with replies and reminders. Badge shows unread counts in real time.',
                        ),
                        const SizedBox(height: 10),
                        _buildGuideRow(
                          icon: Icons.spa,
                          title: 'Resources',
                          description:
                              'Guided meditation, breathing exercises, micro-journals, and campus events in one place.',
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            icon: const Icon(Icons.lightbulb),
                            label: const Text(
                              'Need more help? Explore the app and tap icons to begin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState:
                      _isGuideExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCrisisSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Crisis & Emergency Assistance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCrisisButton('Hotline', Icons.phone, Colors.red, () async {
                  // Open phone dialer with hotline number
                  final uri = Uri.parse('tel:+60146211740');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to open phone dialer')),
                      );
                    }
                  }
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCrisisButton('Chat to Admin', Icons.message, Colors.red, () {
                  // Navigate to chat screen
                  if (widget.user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserChatScreen(user: widget.user!),
                      ),
                    );
                  }
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Mood',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Resources',
          ),
        ],
      ),
    );
  }
}

