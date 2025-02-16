import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle:
            SystemUiOverlayStyle.dark, // Makes status bar icons visible
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(''),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: IconButton(
              icon: Icon(
                FontAwesomeIcons.gear,
                size: 32,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- Logo + Title ---
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 144,
                        height: 144,
                        child: SvgPicture.asset(
                          'assets/logo.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Willkommen zur\nWeinkeller App',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'SFProDisplay',
                          fontSize: 34,
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.w400,
                          height: 41 / 34,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // --- Buttons at the Bottom ---
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "Account Erstellen" Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0, // Removes button shadow
                          backgroundColor: Color(0xFF002032),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/create_user');
                        },
                        child: Text(
                          'Account Erstellen',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontFamily: 'SFProDisplay',
                            fontSize: 17,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w400,
                            height: 22 / 17,
                            letterSpacing: -0.43,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // "Anmelden" Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0, // Removes button shadow
                          backgroundColor:
                              const Color(0xFFEFEFF0), // Custom light gray
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              color: Color(0xFF002032), // The border color
                              width: 3.0, // Border thickness
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: Text(
                          'Anmelden',
                          style: TextStyle(
                            color: Color(0xFF002032),
                            fontFamily: 'SFProDisplay',
                            fontSize: 17,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w400,
                            height: 22 / 17,
                            letterSpacing: -0.43,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
