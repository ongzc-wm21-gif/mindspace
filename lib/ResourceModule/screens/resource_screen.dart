import 'package:flutter/material.dart';
import 'package:calmmind/ResourceModule/screens/campus_event/campus_event_screen.dart';
import 'package:calmmind/ResourceModule/screens/breathing_exercise/breathing_exercise_screen.dart';
import 'package:calmmind/ResourceModule/screens/guided_meditation/guided_meditation_screen.dart';
import 'package:calmmind/ResourceModule/screens/micro_journal/micro_journal_screen.dart';
import 'package:calmmind/UserModule/user_model.dart';

class ResourceScreen extends StatelessWidget {
  final UserModel? user;
  final bool isAdminView; // true if called from admin dashboard, false if from user portal

  const ResourceScreen({super.key, this.user, this.isAdminView = false});

  bool get isAdmin => user?.roleType.toLowerCase() == 'admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Resources'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResourceCard(
            context,
            title: 'Guided Meditation',
            icon: Icons.spa,
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GuidedMeditationScreen(isAdmin: isAdmin),
                ),
              );
            },
          ),
          // Show Breathing Exercise and Micro-Journal in user portal (not in admin dashboard)
          if (!isAdminView) ...[
            const SizedBox(height: 12),
            _buildResourceCard(
              context,
              title: 'Breathing Exercise',
              icon: Icons.air,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BreathingExerciseScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildResourceCard(
              context,
              title: 'Micro-Journal',
              icon: Icons.book,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MicroJournalScreen(),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          _buildResourceCard(
            context,
            title: 'Campus Event',
            icon: Icons.event,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CampusEventScreen(isAdmin: isAdmin),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

