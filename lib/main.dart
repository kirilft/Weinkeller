import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config/routes.dart';
import 'config/app_colors.dart';
import 'config/theme.dart'; // Your ThemeProvider
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'config/font_theme.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize secure storage
    const secureStorage = FlutterSecureStorage();

    // Attempt to read baseUrl from secure storage; fallback to a default if none is found
    final savedBaseUrl = await secureStorage.read(key: 'baseUrl') ?? '';

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
        // Wrap the app in CacheInitializer to update wine cache on launch.
        child: const CacheInitializer(
          child: MyWeinkellerApp(),
        ),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('GLOBAL ERROR HANDLER: $error\nStackTrace: $stackTrace');
  });
}

/// A top-level widget that updates (forces) the wine cache when the app launches.
class CacheInitializer extends StatefulWidget {
  final Widget child;
  const CacheInitializer({Key? key, required this.child}) : super(key: key);

  @override
  _CacheInitializerState createState() => _CacheInitializerState();
}

class _CacheInitializerState extends State<CacheInitializer> {
  @override
  void initState() {
    super.initState();
    // Delay the cache update until after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCache();
    });
  }

  Future<void> _updateCache() async {
    // Retrieve AuthService and ApiService from Provider.
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = authService.authToken;
    if (token != null && token.isNotEmpty) {
      try {
        // Force update the cache by calling updateCache.
        await apiService.updateCache(token: token);
        debugPrint('Wine cache successfully forced updated on app launch.');
      } catch (e) {
        debugPrint('Error updating wine cache on app launch: $e');
      }
    } else {
      debugPrint('No token available on app launch; skipping cache update.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
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
      primaryColor: AppColors.cyan,
      scaffoldBackgroundColor: isLight ? AppColors.white : AppColors.black,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.cyan,
        onPrimary: isLight ? AppColors.white : AppColors.black,
        secondary: AppColors.orange,
        onSecondary: isLight ? AppColors.white : AppColors.black,
        error: isLight ? AppColors.gray2 : AppColors.gray1,
        onError: AppColors.red,
        surface: isLight ? AppColors.white : AppColors.black,
        onSurface: isLight ? AppColors.black : AppColors.white,
        background: isLight ? AppColors.white : AppColors.black,
        onBackground: isLight ? AppColors.black : AppColors.white,
      ),
      textTheme: FontTheme.getTextTheme(brightness),
      fontFamily: 'SF Pro',
    );
  }
}
