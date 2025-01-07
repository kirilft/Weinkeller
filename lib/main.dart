import 'package:flutter/material.dart';
import 'package:weinkeller/pages/account.dart';
import 'package:weinkeller/pages/changelog.dart';
import 'package:weinkeller/pages/history.dart';
import 'package:weinkeller/pages/homescreen.dart';
import 'package:weinkeller/pages/login.dart';
import 'package:weinkeller/pages/menu.dart';
import 'package:weinkeller/pages/password_reset.dart';
import 'package:weinkeller/pages/settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        '/menu': (context) => const MenuPage(),
        '/history': (context) => const HistoryPage(),
        '/changelog': (context) => const ChangelogPage(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
