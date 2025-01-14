// lib/main.dart

import 'dart:async'; // For runZonedGuarded
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
import 'package:weinkeller/pages/qr_result.dart';

// Providers
import 'package:weinkeller/services/theme_provider.dart';

Future<void> main() async {
  // Make sure widgets are bound before using shared prefs or such.
  WidgetsFlutterBinding.ensureInitialized();

  // Use runZonedGuarded to catch all unhandled errors for troubleshooting/logging
  runZonedGuarded(() async {
    // Load the saved baseUrl (if any) from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl = prefs.getString('baseUrl') ?? '';

    // Create the ApiService with the saved baseUrl
    final apiService = ApiService(baseUrl: savedBaseUrl);

    runApp(
      MultiProvider(
        providers: [
          // Provide the ApiService
          Provider<ApiService>(
            create: (_) => apiService,
          ),
          // Provide AuthService
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
  }, (error, stackTrace) {
    if (error is WrongPasswordException) {
      // We can log it or send to analytics
      debugPrint(
          'GLOBAL ERROR HANDLER: WrongPasswordException -> ${error.message}');
    } else {
      debugPrint('GLOBAL ERROR HANDLER: $error\nStackTrace: $stackTrace');
    }
  });
}

class MyWeinkellerApp extends StatelessWidget {
  const MyWeinkellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Weinkeller',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginPage(),
        '/password_reset': (context) => const PasswordResetPage(),
        '/account': (context) => const AccountPage(),
        '/settings': (context) => const SettingsPage(),
        '/history': (context) => const HistoryPage(),
        '/changelog': (context) => const ChangelogPage(),
        '/qrResult': (context) => QRResultPage(
              qrCode: ModalRoute.of(context)!.settings.arguments as String,
            ),
      },
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      themeMode: themeProvider.themeMode,
    );
  }
}
