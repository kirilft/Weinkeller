// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services
import 'package:weinkeller/services/api_service.dart';
import 'package:weinkeller/services/auth_service.dart';

// Pages
import 'package:weinkeller/pages/account.dart';
import 'package:weinkeller/pages/changelog.dart';
import 'package:weinkeller/pages/history.dart';
import 'package:weinkeller/pages/homescreen.dart';
import 'package:weinkeller/pages/login.dart';
import 'package:weinkeller/pages/password_reset.dart';
import 'package:weinkeller/pages/settings.dart';
import 'package:weinkeller/pages/qr_code_result_page.dart';

void main() {
  final apiService = ApiService(baseUrl: 'http://10.20.30.19:5432');

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
      ],
      child: const MyWeinkellerApp(),
    ),
  );
}

class MyWeinkellerApp extends StatelessWidget {
  const MyWeinkellerApp({super.key});

  @override
  Widget build(BuildContext context) {
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
        primarySwatch: Colors.blue,
      ),
    );
  }
}
