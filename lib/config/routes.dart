import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../pages/home_screen.dart';
import '../pages/login.dart';
import '../pages/welcome_screen.dart'; // <--- import the new file
import '../pages/settings.dart';
import '../pages/account.dart';
import '../pages/history.dart';
import '../pages/changelog.dart';
import '../components/qr_result.dart';

class AppRoutes {
  static const String initialRoute = '/';

  static Map<String, WidgetBuilder> get routes {
    return {
      '/': (context) => Consumer<AuthService>(
            builder: (context, authService, _) {
              return authService.isLoggedIn
                  ? const HomeScreen() // If token found => go home
                  : const WelcomeScreen(); // If no token => go welcome
            },
          ),
      '/login': (context) => const LoginPage(),
      '/settings': (context) => const SettingsPage(),
      '/account': (context) => const AccountPage(),
      '/history': (context) => const HistoryPage(),
      '/changelog': (context) => const ChangelogPage(),
      '/qrResult': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return QRResultPage(qrCode: args is String ? args : '');
      },
    };
  }
}
