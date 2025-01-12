import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String randomGreeting;
  const AppDrawer({required this.randomGreeting, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: ListView(
        children: [
          SizedBox(
            height: 100,
            child: DrawerHeader(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : const Color(0xFFFF453A),
              ),
              child: Center(
                child: Text(
                  randomGreeting,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.settings,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            title: const Text('Settings'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          ListTile(
            leading: Icon(
              Icons.history,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            title: const Text('History'),
            onTap: () => Navigator.pushNamed(context, '/history'),
          ),
          ListTile(
            leading: Icon(
              Icons.info,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            title: const Text('Changelog'),
            onTap: () => Navigator.pushNamed(context, '/changelog'),
          ),
        ],
      ),
    );
  }
}
