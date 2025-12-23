import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:calmmind/UserModule/forgot_password_screen.dart';
import 'package:calmmind/UserModule/home_page.dart';
import 'package:calmmind/database/supabase_service.dart';
import 'package:calmmind/UserModule/user_model.dart';
import 'package:calmmind/UserModule/admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  // Blue theme color matching homepage
  static const Color primaryBlue = Color(0xFF2196F3);
  
  final SupabaseService _dbHelper = SupabaseService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        // ========== LOGIN WITH SUPABASE AUTH ==========
        final response = await _supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.user == null) {
          setState(() {
            _error = 'Login failed. Please check your credentials.';
            _isLoading = false;
          });
          return;
        }

        // Check if email is confirmed (optional - can be disabled for development)
        // For development, you can comment out this check if email confirmation is disabled
        if (response.user!.emailConfirmedAt == null) {
          setState(() {
            _error = 'Please confirm your email before logging in. Check your inbox for the confirmation link.\n\nOr disable email confirmation in Supabase Dashboard → Authentication → Settings';
            _isLoading = false;
          });
          return;
        }

        // Get user profile from our users table
        var user = await _dbHelper.getUserByAuthUid(response.user!.id);
        
        // If profile doesn't exist, create it (for users who confirmed email but profile wasn't created)
        if (user == null) {
          try {
            // Extract username from email if not in metadata
            final username = response.user!.userMetadata?['username'] as String? ?? 
                           _emailController.text.trim().split('@').first;
            
            final newUser = UserModel(
              authUid: response.user!.id,
              username: username,
              email: response.user!.email ?? _emailController.text.trim(),
              phoneNumber: response.user!.userMetadata?['phoneNumber'] as String?,
              roleType: response.user!.userMetadata?['roleType'] as String? ?? 'user',
              dateJoin: DateTime.now().toIso8601String(),
            );

            await _dbHelper.insertUserProfile(newUser);
            
            // Get the created profile
            user = await _dbHelper.getUserByAuthUid(response.user!.id);
          } catch (e) {
            print('Error creating profile on login: $e');
            print('Full error: ${e.toString()}');
            setState(() {
              // Show the actual error message for debugging
              final errorMsg = e.toString();
              if (errorMsg.contains('RLS') || errorMsg.contains('policy') || errorMsg.contains('permission')) {
                _error = 'Profile creation blocked. Please check RLS policies in Supabase.\n\nError: ${errorMsg.length > 100 ? errorMsg.substring(0, 100) + "..." : errorMsg}';
              } else {
                _error = 'Profile creation failed: ${errorMsg.length > 150 ? errorMsg.substring(0, 150) + "..." : errorMsg}';
              }
              _isLoading = false;
            });
            return;
          }
        }
        
        if (user == null) {
          setState(() {
            _error = 'User profile not found. Please contact support.';
            _isLoading = false;
          });
          return;
        }

        // Block admins from using the user portal
        final isAdmin = (user.roleType).toLowerCase() == 'admin';
        if (isAdmin) {
          await _supabase.auth.signOut();
          if (mounted) {
            setState(() {
              _error = 'Only users can sign in to the user portal. Admins should use the Admin Portal.';
              _isLoading = false;
            });
          }
          return;
        }

        // Successful login - navigate to home with user data
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(user: user),
            ),
          );
        }
      } else {
        // ========== SIGN UP WITH SUPABASE AUTH ==========
        // Check if email already exists
        final emailExists = await _dbHelper.emailExists(_emailController.text.trim());
        if (emailExists) {
          setState(() {
            _error = 'Email already exists. Please login instead.';
            _isLoading = false;
          });
          return;
        }

        // Check if username already exists
        final usernameExists = await _dbHelper.usernameExists(_usernameController.text.trim());
        if (usernameExists) {
          setState(() {
            _error = 'Username already taken. Please choose another.';
            _isLoading = false;
          });
          return;
        }

        // Sign up with Supabase Auth
        final response = await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {
            'username': _usernameController.text.trim(),
            'phoneNumber': _phoneController.text.trim().isEmpty 
                ? null 
                : _phoneController.text.trim(),
            'roleType': 'user', // Default role
          },
        );

        if (response.user == null) {
          setState(() {
            _error = 'Sign up failed. Please try again.';
            _isLoading = false;
          });
          return;
        }

        // Check if email confirmation is required
        if (response.user!.emailConfirmedAt == null) {
          setState(() {
            _error = 'Account created! Please check your email to confirm your account before logging in.';
            _isLoading = false;
          });
          return;
        }

        // Manually create user profile (more reliable than relying on trigger)
        try {
          final newUser = UserModel(
            authUid: response.user!.id,
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty 
                ? null 
                : _phoneController.text.trim(),
            roleType: 'user',
            dateJoin: DateTime.now().toIso8601String(),
          );

          await _dbHelper.insertUserProfile(newUser);
        } catch (e) {
          // If profile creation fails, the trigger might have created it
          // We'll try to get it anyway below
          print('Profile creation error (might already exist): $e');
        }

        // Wait a moment for database to sync
        await Future.delayed(const Duration(milliseconds: 500));

        // Get the created user profile
        final user = await _dbHelper.getUserByAuthUid(response.user!.id);
        
        if (user == null) {
          setState(() {
            _error = 'Account created but profile not found. Please try logging in.';
            _isLoading = false;
          });
          return;
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(user: user),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      // Handle Supabase Auth errors
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isLogin) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      hintText: 'Enter your phone number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
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
                      : Text(
                          _isLogin ? 'Login' : 'Sign Up',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (_isLogin) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: primaryBlue),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _error = null;
                    });
                  },
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign Up"
                        : 'Already have an account? Login',
                    style: const TextStyle(color: primaryBlue),
                  ),
                ),
                const SizedBox(height: 8),
                // Admin Login Link
                if (_isLogin)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminLoginScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings, size: 18),
                    label: const Text(
                      'Admin Login',
                      style: TextStyle(color: primaryBlue),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

