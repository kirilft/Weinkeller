import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// NEW: import flutter_secure_storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize secure storage
    const secureStorage = FlutterSecureStorage();

    // Attempt to read baseUrl from secure storage; fallback to a default if none is found
    final savedBaseUrl =
        await secureStorage.read(key: 'baseUrl') ?? 'http://localhost:80/api';

    // Create the ApiService with the base URL
    final apiService = ApiService(baseUrl: savedBaseUrl);

    // Create the AuthService with the ApiService
    final authService = AuthService(apiService: apiService);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ApiService>(
            create: (_) => apiService,
          ),
          ChangeNotifierProvider<AuthService>(
            create: (_) => authService,
          ),
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(),
          ),
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
