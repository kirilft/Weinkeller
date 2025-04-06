import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/api_service.dart';
import 'package:weinkeller/services/auth_service.dart';

const List<Shadow> kTextShadow = [
  Shadow(
    offset: Offset(0, 4),
    blurRadius: 4,
    color: Color.fromARGB(25, 0, 0, 0),
  ),
];

final List<BoxShadow> kBoxShadow = [
  BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 4,
    color: Colors.black.withAlpha(25),
  ),
];

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
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
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
            fontFamily: 'SFProDisplay',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 20 / 15,
            letterSpacing: -0.23,
          ),
        ),
      ),
    );
  }
}

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(shadows: kTextShadow),
        ),
        content: Text(
          message,
          style: const TextStyle(shadows: kTextShadow),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Future<void> _handleCreateUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      _showErrorDialog("Validierungsfehler", "Name darf nicht leer sein. :3");
      return;
    }
    if (email.isEmpty) {
      _showErrorDialog("Validierungsfehler", "E-Mail darf nicht leer sein. :3");
      return;
    }
    if (password.isEmpty) {
      _showErrorDialog(
          "Validierungsfehler", "Passwort darf nicht leer sein. :3");
      return;
    }
    if (password != confirmPassword) {
      _showErrorDialog(
          "Validierungsfehler", "Passwörter stimmen nicht überein. :3");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      await apiService.registerUser(
        username: name,
        email: email,
        password: password,
      );

      final loginSuccess = await authService.login(email, password);
      if (loginSuccess) {
        Navigator.pushReplacementNamed(context, '/');
      } else {
        _showErrorDialog("Anmeldefehler",
            "Konto erstellt, aber automatische Anmeldung fehlgeschlagen. :3");
      }
    } catch (e) {
      _showErrorDialog("Registrierungsfehler", e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      centerTitle: true,
      title: Text(
        'Konto',
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontFamily: 'SFProDisplay',
          fontSize: 28,
          fontWeight: FontWeight.w400,
          height: 34 / 28,
          letterSpacing: -0.38,
          shadows: kTextShadow,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 32),
        child: IconButton(
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            size: 32,
            color: theme.colorScheme.onSurface,
            shadows: kTextShadow,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: IconButton(
            icon: FaIcon(
              FontAwesomeIcons.gear,
              size: 32,
              color: theme.colorScheme.onSurface,
              shadows: kTextShadow,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.15),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-Mail'),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Passwort'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _confirmPasswordController,
              decoration:
                  const InputDecoration(labelText: 'Passwort bestätigen'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ShadowedButton(
                      label: 'Erstellen',
                      backgroundColor: theme.colorScheme.primary,
                      textColor: theme.colorScheme.onPrimary,
                      onPressed: _handleCreateUser,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
