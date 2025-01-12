import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomNavBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback showManualCodeDialog;
  const BottomNavBar({
    required this.scaffoldKey,
    required this.showManualCodeDialog,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDarkMode ? Colors.black87 : const Color(0xFF000000),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.menu,
              size: 30,
              color: isDarkMode ? Colors.white : Colors.white,
            ),
            onPressed: () => scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Open Menu',
          ),
          ElevatedButton(
            onPressed: showManualCodeDialog,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(18),
              backgroundColor: Colors.white,
            ),
            child: Icon(
              FontAwesomeIcons.qrcode,
              size: 40,
              color: Colors.black,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.person,
              size: 30,
              color: isDarkMode ? Colors.white : Colors.white,
            ),
            onPressed: () => Navigator.pushNamed(context, '/account'),
            tooltip: 'Open Account',
          ),
        ],
      ),
    );
  }
}
