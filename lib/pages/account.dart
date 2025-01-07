// lib/pages/account.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/auth_service.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: authService.isLoggedIn
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You are logged in!'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await authService.logout();
                      // After logging out, go back to Home
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: const Text('Log Out'),
                  ),
                ],
              ),
            )
          : Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Log In'),
              ),
            ),
    );
  }
}
