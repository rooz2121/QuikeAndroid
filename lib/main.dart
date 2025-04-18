import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'pages/main_chat_page..dart';
import 'pages/backend/login_page.dart';
import 'pages/settings_page.dart';
import 'pages/about_page.dart';
import 'pages/help_page.dart';
import 'services/supabase_service.dart';
import 'utils/date_time_utils.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize timezone data
  DateTimeUtils.initialize();
  
  // Initialize Supabase
  await SupabaseService().initialize();
  
  // Set environment-specific configurations
  final appConfig = AppConfig();
  
  // Disable debug banner and set up production configurations
  if (kReleaseMode) {
    // Disable logs in production
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  
  runApp(MyApp(appConfig: appConfig));
}

class MyApp extends StatelessWidget {
  final AppConfig appConfig;
  
  const MyApp({super.key, required this.appConfig});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Always disable debug banner for release
      title: appConfig.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => _buildHomeScreen(),
        '/chat': (context) => const ChatPage(),
        '/settings': (context) => const SettingsPage(),
        '/about': (context) => const AboutPage(),
        '/help': (context) => const HelpPage(),
      },
    );
  }
  
  Widget _buildHomeScreen() {
    final supabaseService = SupabaseService();
    if (supabaseService.isLoggedIn) {
      return const ChatPage();
    } else {
      return const LoginPage();
    }
  }
}
