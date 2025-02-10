import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config/routes.dart';
import 'config/app_colors.dart';
import 'config/theme.dart'; // Your ThemeProvider
import 'services/api_service.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize secure storage
    const secureStorage = FlutterSecureStorage();

    // Attempt to read baseUrl from secure storage; fallback to a default if none is found
    final savedBaseUrl = await secureStorage.read(key: 'baseUrl') ??
        '';

    // Create the ApiService with the base URL
    final apiService = ApiService(baseUrl: savedBaseUrl);

    // Create the AuthService with the ApiService
    final authService = AuthService(apiService: apiService);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ApiService>(create: (_) => apiService),
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
      initialRoute: AppRoutes.initialRoute,
      routes: AppRoutes.routes,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeProvider.themeMode,
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      brightness: brightness,
      primaryColor: isLight ? AppColors.blueLight : AppColors.blueDark,
      // New design: pure white for light mode and pure black for dark mode
      scaffoldBackgroundColor:
          isLight ? AppColors.whiteLight : AppColors.blackDark,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: isLight ? AppColors.blueLight : AppColors.blueDark,
        onPrimary: isLight ? AppColors.whiteLight : AppColors.whiteDark,
        secondary: isLight ? AppColors.greenLight : AppColors.greenDark,
        onSecondary: isLight ? AppColors.whiteLight : AppColors.whiteDark,
        error: isLight ? AppColors.redLight : AppColors.redDark,
        onError: isLight ? AppColors.whiteLight : AppColors.whiteDark,
        // Using the new background for surface as well
        surface: isLight ? AppColors.whiteLight : AppColors.blackDark,
        onSurface: isLight ? AppColors.blackLight : AppColors.whiteDark,
      ),
      fontFamily: 'SFProDisplay',
    );
  }
}
