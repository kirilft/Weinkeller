import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/auth_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context, listen: false);

    // If not logged in, immediately push the login screen
    if (!authService.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // If we made it this far, the user must be logged in
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Center(
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
      ),
    );
  }
}
