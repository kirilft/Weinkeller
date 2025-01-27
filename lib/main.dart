import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/theme_provider.dart';

import 'pages/account.dart';
import 'pages/changelog.dart';
import 'pages/history.dart';
import 'pages/home_screen.dart';
import 'pages/login.dart';
import 'pages/password_reset.dart';
import 'pages/settings.dart';
import 'pages/qr_result.dart';

void main() {
  // Use runZonedGuarded to catch unhandled errors globally
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Load the saved base URL (if any) from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl =
        prefs.getString('baseUrl') ?? 'http://localhost:80/api';

    // Create the services
    final apiService = ApiService(baseUrl: savedBaseUrl);
    final authService = AuthService(apiService);

    runApp(
      MultiProvider(
        providers: [
          Provider<ApiService>(create: (_) => apiService),
          ChangeNotifierProvider<AuthService>(create: (_) => authService),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ],
        child: const MyWeinkellerApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('GLOBAL ERROR HANDLER: $error\nStackTrace: $stackTrace');
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
        '/': (context) => Consumer<AuthService>(
              builder: (context, authService, _) {
                return authService.isLoggedIn
                    ? const HomeScreen()
                    : const LoginPage();
              },
            ),
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
        fontFamily: 'SFProDisplay',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        fontFamily: 'SFProDisplay',
      ),
      themeMode: themeProvider.themeMode,
    );
  }
}
