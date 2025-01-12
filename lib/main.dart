// lib/main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// Services
import 'package:weinkeller/services/api_service.dart';
import 'package:weinkeller/services/auth_service.dart';

// Pages
import 'package:weinkeller/pages/account.dart';
import 'package:weinkeller/pages/changelog.dart';
import 'package:weinkeller/pages/history.dart';
import 'package:weinkeller/pages/home_screen.dart';
import 'package:weinkeller/pages/login.dart';
import 'package:weinkeller/pages/password_reset.dart';
import 'package:weinkeller/pages/settings.dart';
import 'package:weinkeller/pages/qr_code_result_page.dart';

// Providers
import 'package:weinkeller/services/theme_provider.dart'; // Import ThemeProvider

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the saved baseUrl (if any) from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final savedBaseUrl = prefs.getString('baseUrl') ?? '';

  // Create the ApiService with the saved baseUrl
  final apiService = ApiService(baseUrl: savedBaseUrl);

  runApp(
    MultiProvider(
      providers: [
        // Provide the ApiService to the whole app
        Provider<ApiService>(
          create: (_) => apiService,
        ),
        // Provide AuthService that consumes ApiService
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(apiService: apiService),
        ),
        // Provide ThemeProvider
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const MyWeinkellerApp(),
    ),
  );
}

class MyWeinkellerApp extends StatelessWidget {
  const MyWeinkellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Weinkeller',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginPage(),
        '/password_reset': (context) => const PasswordResetPage(),
        '/account': (context) => const AccountPage(),
        '/settings': (context) => const SettingsPage(),
        '/history': (context) => const HistoryPage(),
        '/changelog': (context) => const ChangelogPage(),
        '/qrResult': (context) {
          // Retrieve arguments passed via Navigator.pushNamed(..., arguments: ...)
          final args = ModalRoute.of(context)!.settings.arguments as String?;
          return QrCodeResultPage(
            qrData: args ?? 'No data',
          );
        },
      },
      theme: ThemeData(
        brightness: Brightness.light, // Define light theme
        primarySwatch: Colors.blue,
        // You can customize more properties for the light theme here
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark, // Define dark theme
        primarySwatch: Colors.blue,
        // You can customize more properties for the dark theme here
      ),
      themeMode:
          themeProvider.themeMode, // Use the theme mode from ThemeProvider
    );
  }
}
