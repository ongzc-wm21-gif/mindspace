import 'package:flutter/material.dart';
import '../database/supabase_service.dart';

class PromoteAdminScreen extends StatefulWidget {
  const PromoteAdminScreen({super.key});

  @override
  State<PromoteAdminScreen> createState() => _PromoteAdminScreenState();
}

class _PromoteAdminScreenState extends State<PromoteAdminScreen> {
  final SupabaseService _dbHelper = SupabaseService.instance;
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  // Blue theme color matching homepage
  static const Color primaryBlue = Color(0xFF2196F3);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _promoteToAdmin() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _message = 'Please enter an email address';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _isError = false;
    });

    try {
      final user = await _dbHelper.getUserByEmail(_emailController.text.trim());
      
      if (user == null) {
        setState(() {
          _message = 'User not found with this email.';
          _isError = true;
          _isLoading = false;
        });
        return;
      }

      if (user.roleType.toLowerCase() == 'admin') {
        setState(() {
          _message = 'User is already an admin.';
          _isError = false;
          _isLoading = false;
        });
        return;
      }

      // Update user role to admin
      final updatedUser = user.copyWith(roleType: 'admin');
      await _dbHelper.updateUser(updatedUser);

      setState(() {
        _message = 'User ${user.username} has been promoted to admin successfully!';
        _isError = false;
        _isLoading = false;
      });

      _emailController.clear();
    } catch (e) {
      setState(() {
        _message = 'Error: ${e.toString()}';
        _isError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promote to Admin'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 64,
                color: primaryBlue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Promote User to Admin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the email of the user you want to promote to admin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'User Email',
                  hintText: 'Enter user email address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isError ? Colors.red.shade200 : Colors.green.shade200,
                    ),
                  ),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _promoteToAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Promote to Admin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Alternative Methods:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildMethodCard(
                'Method 1: SQLite Browser',
                'Use a SQLite browser tool to directly edit the database file.',
                Icons.storage,
              ),
              const SizedBox(height: 12),
              _buildMethodCard(
                'Method 2: SQL Command',
                'Run SQL: UPDATE users SET roleType = "admin" WHERE email = "user@email.com"',
                Icons.code,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard(String title, String description, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: primaryBlue, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

