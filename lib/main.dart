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
import 'services/sync_service.dart';
import 'services/database_service.dart'; // Added DatabaseService
import 'services/api_manager.dart'; // Added ApiManager import

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize secure storage.
    const secureStorage = FlutterSecureStorage();

    // Attempt to read baseUrl from secure storage; fallback to an empty string if none is found.
    final savedBaseUrl = await secureStorage.read(key: 'baseUrl') ?? '';

    // Create the ApiService with the base URL.
    final apiService = ApiService(baseUrl: savedBaseUrl);

    // Create the AuthService with the ApiService.
    final authService = AuthService(apiService: apiService);

    // Create the DatabaseService (singleton).
    final databaseService = DatabaseService();

    // Create the ApiManager.
    final apiManager =
        ApiManager(apiService: apiService, databaseService: databaseService);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ApiService>(create: (_) => apiService),
          ChangeNotifierProvider<AuthService>(create: (_) => authService),
          Provider<DatabaseService>(create: (_) => databaseService),
          Provider<ApiManager>(create: (_) => apiManager), // <-- Add this
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<SyncService>(
            create: (_) => SyncService(
                apiService: apiService,
                databaseService: databaseService,
                syncInterval: const Duration(seconds: 300)),
          ),
        ],
        // Wrap the app in AppInitializer to perform initial checks.
        child: const AppInitializer(
          child: MyWeinkellerApp(),
        ),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('GLOBAL ERROR HANDLER: $error\nStackTrace: $stackTrace');
  });
}

/// A top-level widget that initializes the app state by invoking AuthService.initialize()
/// and starting the sync service if a valid token is available.
class AppInitializer extends StatefulWidget {
  final Widget child;
  const AppInitializer({super.key, required this.child});

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Perform initialization after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.initialize(context);
      if (authService.authToken != null && authService.authToken!.isNotEmpty) {
        final syncService = Provider.of<SyncService>(context, listen: false);
        syncService.startSync(authService.authToken!);
        debugPrint('Sync service started with token.');
      }
    });
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

/// Widget to notify locale changes.
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
