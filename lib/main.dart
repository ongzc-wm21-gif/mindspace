import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindspace/UserModule/login_screen.dart';
import 'package:mindspace/UserModule/reset_password_screen.dart';
import 'package:mindspace/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    print('✅ Supabase initialized successfully!');
    print('🌐 Connected to: ${SupabaseConfig.supabaseUrl}');
  } catch (e) {
    print('❌ Supabase initialization error: $e');
  }
  
  runApp(const MindSpaceApp());
}

class MindSpaceApp extends StatefulWidget {
  const MindSpaceApp({super.key});

  @override
  State<MindSpaceApp> createState() => _MindSpaceAppState();
}

class _MindSpaceAppState extends State<MindSpaceApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Listen for deep links (password reset)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (event == AuthChangeEvent.passwordRecovery && session != null) {
        // User clicked password reset link, navigate to reset password screen
        _handlePasswordReset();
      }
    });
  }

  void _handlePasswordReset() {
    // Navigate to reset password screen when deep link is opened
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => const ResetPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'MindSpace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3), // Blue color
          primary: const Color(0xFF2196F3),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
      // Handle deep links
      onGenerateRoute: (settings) {
        if (settings.name == '/reset-password') {
          return MaterialPageRoute(
            builder: (context) => const ResetPasswordScreen(),
          );
        }
        return null;
      },
    );
  }
}
