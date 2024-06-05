import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../components/input_field.dart';
import '../services/auth.dart';
import '../theme/theme.dart'; // Update this import with your actual path

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    final success = await _authService.login(username, password);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Navigate to the dashboard or another screen
      Navigator.pushNamed(context, '/items');
    } else {
      // Show an error message
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Login Failed'),
            content: Text('Invalid username or password.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: constraints.maxHeight,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                    ),
                    child: SvgPicture.asset(
                      'assets/login.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child:Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Login', style: AppTheme.headline1),
                    SizedBox(height: 20),
                    CustomTextField(
                      controller: _usernameController,
                      label: 'Username',
                    ),
                    SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      obscureText: true,
                    ),
                    SizedBox(height: 20),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _handleLogin,
                      style: AppTheme.elevatedButtonStyle,
                      child: Text('Login', style: AppTheme.button),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
