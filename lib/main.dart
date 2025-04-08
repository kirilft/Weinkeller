import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Assuming these imports are correct for your project structure
import 'config/routes.dart';
import 'config/app_colors.dart';
import 'config/theme.dart'; // Assuming ThemeProvider is here
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'services/database_service.dart';
import 'services/api_manager.dart';
import 'services/history_service.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Use runZonedGuarded for top-level error handling.
  runZonedGuarded(() async {
    // Initialize secure storage.
    const secureStorage = FlutterSecureStorage();

    // Attempt to read baseUrl from secure storage; fallback to an empty string if none is found.
    final savedBaseUrl = await secureStorage.read(key: 'baseUrl') ?? '';

    // --- Service Initialization ---
    final apiService = ApiService(baseUrl: savedBaseUrl);
    final authService = AuthService(apiService: apiService);
    final databaseService = DatabaseService();
    final historyService = HistoryService();
    final apiManager = ApiManager(
      apiService: apiService,
      databaseService: databaseService,
      historyService: historyService,
    );
    final syncService = SyncService(
      apiService: apiService,
      databaseService: databaseService,
      syncInterval: const Duration(minutes: 5), // Or seconds: 5 for testing
    );

    runApp(
      // Use MultiProvider to make services available down the widget tree.
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ApiService>(create: (_) => apiService),
          ChangeNotifierProvider<AuthService>(create: (_) => authService),
          Provider<DatabaseService>(
              create: (_) => databaseService,
              dispose: (_, service) => service.dispose()), // Dispose DB service
          Provider<ApiManager>(create: (_) => apiManager),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<SyncService>(
              create: (_) => syncService), // Provide SyncService
        ],
        child: const AppInitializer(
          child: MyWeinkellerApp(),
        ),
      ),
    );
  }, (error, stackTrace) {
    // Global error handler: Logs uncaught errors.
    debugPrint('GLOBAL ERROR HANDLER: $error\nStackTrace: $stackTrace');
  });
}

/// A top-level widget that initializes the app state:
/// 1. Initializes AuthService (checks for token, navigates if needed).
/// 2. Performs an initial data sync if logged in.
/// 3. Starts the periodic sync service if logged in.
class AppInitializer extends StatefulWidget {
  final Widget child;
  const AppInitializer({super.key, required this.child});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Perform initialization after the first frame to ensure context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return; // Check if the widget is still mounted
      final authService = Provider.of<AuthService>(context, listen: false);
      final syncService = Provider.of<SyncService>(context, listen: false);

      // Initialize authentication (checks token, base URL etc.)
      await authService.initialize(context);

      // After auth initialization, check if we have a valid token.
      if (mounted &&
          authService.authToken != null &&
          authService.authToken!.isNotEmpty) {
        final token = authService.authToken!;
        debugPrint(
            'AppInitializer: User logged in. Performing initial sync...');

        // ** Perform Initial Sync on Launch **
        try {
          // Await the initial sync to ensure cache is updated before user interacts heavily.
          await syncService.updatePendingOperationsAndFetch(token);
          debugPrint('AppInitializer: Initial sync completed.');
        } catch (e) {
          // Log error during initial sync but don't crash the app.
          debugPrint('AppInitializer: Error during initial sync: $e');
        }

        // ** Start Periodic Sync **
        // Start the timer for subsequent background syncs.
        syncService.startSync(token);
        debugPrint('AppInitializer: Periodic sync service started.');
      } else {
        debugPrint(
            'AppInitializer: User not logged in or no token found. Skipping initial sync and periodic sync start.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Render the main app widget passed as child.
    return widget.child;
  }
}

/// The main application widget.
class MyWeinkellerApp extends StatelessWidget {
  const MyWeinkellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider to apply the current theme.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Weinkeller',
      debugShowCheckedModeBanner: false, // Hide debug banner
      initialRoute: AppRoutes.initialRoute, // Set initial route
      routes: AppRoutes.routes, // Define app routes
      // Use the _buildTheme method directly again
      theme: _buildTheme(Brightness.light), // Light theme data
      darkTheme: _buildTheme(Brightness.dark), // Dark theme data
      themeMode: themeProvider.themeMode, // Control theme based on provider
    );
  }

  // Restored _buildTheme method from the user's provided "old" version
  ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      brightness: brightness,
      primaryColor: AppColors.cyan,
      scaffoldBackgroundColor: isLight
          ? AppColors.white
          : AppColors.black, // Original scaffold colors
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.cyan,
        onPrimary:
            isLight ? AppColors.white : AppColors.black, // Original onPrimary
        secondary: AppColors.orange,
        onSecondary:
            isLight ? AppColors.white : AppColors.black, // Original onSecondary
        // Original error colors
        error: isLight ? AppColors.gray2 : AppColors.gray1,
        onError: AppColors.red, // Original onError
        surface:
            isLight ? AppColors.white : AppColors.black, // Original surface
        onSurface:
            isLight ? AppColors.black : AppColors.white, // Original onSurface
        // These were not explicitly defined in the original _buildTheme, so omit them
        // to avoid potential errors or unwanted visual changes.
        // surfaceVariant: ...,
        // onSurfaceVariant: ...,
        // outline: ...,
        // background: ...,
        // onBackground: ...,
      ),
      fontFamily: 'SF Pro', // Original font family
      // Component themes like AppBarTheme, TextTheme, ElevatedButtonTheme
      // were not in the original _buildTheme, so they are omitted here.
    );
  }
}
