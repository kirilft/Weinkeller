import 'package:flutter/material.dart';
import 'package:weinkeller/pages/account.dart';
import 'package:weinkeller/pages/menu.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Weinkeller",
      initialRoute: '/',
      routes: {
        '/menu': (context) => const MenuPage(),
        '/account': (context) => const AccountPage(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}
