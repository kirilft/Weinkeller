import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_colors.dart';

// --- Common Styling Constants ---
const List<Shadow> kTextShadow = [
  Shadow(
    offset: Offset(0, 4),
    blurRadius: 4,
    color: Color.fromARGB(80, 0, 0, 0),
  ),
];

final List<BoxShadow> kBoxShadow = [
  BoxShadow(
    offset: const Offset(0, 4),
    blurRadius: 4,
    color: Colors.black.withAlpha(80),
  ),
];

// --- Custom Reusable Button Widget ---
class ShadowedButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;
  final BorderSide? borderSide;

  const ShadowedButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: kBoxShadow,
        borderRadius: BorderRadius.circular(30),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: backgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              side: borderSide ?? BorderSide.none,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontFamily: 'SF Pro',
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 22 / 17,
              letterSpacing: -0.43,
            ),
          ),
        ),
      ),
    );
  }
}

// --- Main WelcomeScreen Widget ---
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(context, theme),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildLogoSection(context, theme)),
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: _buildButtonsSection(context, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      automaticallyImplyLeading: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: IconButton(
            iconSize: 48,
            padding: EdgeInsets.zero,
            icon: FaIcon(
              FontAwesomeIcons.gear,
              color: theme.colorScheme.onSurface,
              shadows: kTextShadow,
              size: 32,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 144,
            height: 144,
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Willkommen zur\nWeinkeller App',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontFamily: 'SF Pro',
              fontSize: 34,
              fontWeight: FontWeight.w400,
              height: 41 / 34,
              letterSpacing: 0.4,
              shadows: kTextShadow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonsSection(BuildContext context, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShadowedButton(
          label: 'Account Erstellen',
          backgroundColor: AppColors.gray1,
          textColor: theme.colorScheme.onPrimary,
          onPressed: () {
            Navigator.pushNamed(context, '/create_user');
          },
        ),
        const SizedBox(height: 24),
        ShadowedButton(
          label: 'Anmelden',
          backgroundColor: AppColors.gray2,
          textColor: AppColors.gray1,
          borderSide: const BorderSide(
            color: AppColors.gray1,
            width: 3.0,
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
        ),
      ],
    );
  }
}
