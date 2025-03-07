import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart'; // Localization import

import 'config/routes.dart';
import 'config/app_colors.dart';
import 'config/theme.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

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
  const CacheInitializer({super.key, required this.child});

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
        debugPrint('Wine cache successfully updated on app launch.');
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

class MyWeinkellerApp extends StatefulWidget {
  const MyWeinkellerApp({super.key});

  @override
  _MyWeinkellerAppState createState() => _MyWeinkellerAppState();
}

class _MyWeinkellerAppState extends State<MyWeinkellerApp> {
  Locale _locale = const Locale('en'); // Default language

  void _changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

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
      locale: _locale, // Set current locale
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return LanguageChangeNotifier(
          onLocaleChanged: _changeLocale,
          child: child ?? const SizedBox(),
        );
      },
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
      ),
      fontFamily: 'SF Pro',
    );
  }
}

/// Widget to notify locale changes
class LanguageChangeNotifier extends InheritedWidget {
  final Function(Locale) onLocaleChanged;

  const LanguageChangeNotifier({
    super.key,
    required this.onLocaleChanged,
    required super.child,
  });

  static LanguageChangeNotifier? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LanguageChangeNotifier>();
  }

  @override
  bool updateShouldNotify(LanguageChangeNotifier oldWidget) {
    return onLocaleChanged != oldWidget.onLocaleChanged;
  }
}
