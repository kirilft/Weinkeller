import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(() async {
    // Load the baseURL from SharedPreferences (or use a default)
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl =
        prefs.getString('baseUrl') ?? 'http://localhost:80/api';
    debugPrint('MAIN: Loaded baseURL from prefs: $savedBaseUrl');

    // Create an ApiService instance using the saved baseURL
    final apiService = ApiService(baseUrl: savedBaseUrl);

    // Create AuthService, which will also check for a stored token
    final authService = AuthService(apiService: apiService);

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
  }, (error, stack) {
    debugPrint('GLOBAL ERROR HANDLER: $error\nStackTrace: $stack');
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
      initialRoute: AppRoutes.initialRoute,
      routes: AppRoutes.routes,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeProvider.themeMode,
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      primarySwatch: Colors.blue,
      fontFamily: 'SFProDisplay',
    );
  }
}
