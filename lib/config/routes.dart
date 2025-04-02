import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../pages/home_screen.dart';
import '../pages/login.dart';
import '../pages/welcome_screen.dart';
import '../pages/settings.dart';
import '../pages/account.dart';
import '../pages/history.dart';
import '../components/EntryDetailsPage.dart';
import '../pages/create_user.dart';
import '../pages/web_ui.dart';

class AppRoutes {
  static const String initialRoute = '/';

  static Map<String, WidgetBuilder> get routes {
    return {
      '/': (context) => Consumer<AuthService>(
            builder: (context, authService, _) {
              return authService.isLoggedIn
                  ? const HomeScreen() // If token found, go home
                  : const WelcomeScreen(); // If no token, go to welcome
            },
          ),
      '/login': (context) => const LoginPage(),
      '/settings': (context) => const SettingsPage(),
      '/account': (context) => const AccountPage(),
      '/history': (context) => const HistoryPage(),
      '/webui': (context) => const WebUIView(),
      '/entryDetails': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return EntryDetailsPage(entryId: args is String ? args : '');
      },
      '/create_user': (context) => const CreateUserPage(),
    };
  }
}
