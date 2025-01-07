import 'package:flutter/material.dart';

class DebugMenu extends StatelessWidget {
  const DebugMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return ListView(
              children: [
                ListTile(
                  title: const Text('Home Screen'),
                  onTap: () {
                    Navigator.pushNamed(context, '/');
                  },
                ),
                ListTile(
                  title: const Text('Login Page'),
                  onTap: () {
                    Navigator.pushNamed(context, '/login');
                  },
                ),
                ListTile(
                  title: const Text('Password Reset'),
                  onTap: () {
                    Navigator.pushNamed(context, '/password_reset');
                  },
                ),
                ListTile(
                  title: const Text('Account Page'),
                  onTap: () {
                    Navigator.pushNamed(context, '/account');
                  },
                ),
                ListTile(
                  title: const Text('Settings Page'),
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                ListTile(
                  title: const Text('Menu Page'),
                  onTap: () {
                    Navigator.pushNamed(context, '/menu');
                  },
                ),
                ListTile(
                  title: const Text('History Page'),
                  onTap: () {
                    Navigator.pushNamed(context, '/history');
                  },
                ),
                ListTile(
                  title: const Text('Changelog Page'),
                  onTap: () {
                    Navigator.pushNamed(context, '/changelog');
                  },
                ),
              ],
            );
          },
        );
      },
      child: const Icon(Icons.menu),
    );
  }
}
