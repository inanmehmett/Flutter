import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _userNameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    print('🔐 [SignInForm] ===== INITIALIZATION =====');
    print('🔐 [SignInForm] SignInForm initialized');
    print('🔐 [SignInForm] Remember Me default: $_rememberMe');
    print('🔐 [SignInForm] Password obscured default: $_obscurePassword');
    print('🔐 [SignInForm] ===== INITIALIZATION COMPLETE =====');
  }

  @override
  void dispose() {
    print('🔐 [SignInForm] ===== DISPOSAL =====');
    print('🔐 [SignInForm] Disposing SignInForm');
    _userNameOrEmailController.dispose();
    _passwordController.dispose();
    print('🔐 [SignInForm] Controllers disposed');
    print('🔐 [SignInForm] ===== DISPOSAL COMPLETE =====');
    super.dispose();
  }

  void _signIn() {
    print('🔐 [SignInForm] ===== SIGN IN ATTEMPT =====');
    print('🔐 [SignInForm] Form validation started');

    if (_formKey.currentState!.validate()) {
      print('🔐 [SignInForm] ✅ Form validation passed');

      final userNameOrEmail = _userNameOrEmailController.text.trim();
      final password = _passwordController.text;

      print('🔐 [SignInForm] Username/Email: $userNameOrEmail');
      print('🔐 [SignInForm] Password length: ${password.length}');
      print('🔐 [SignInForm] Remember Me: $_rememberMe');

      print('🔐 [SignInForm] Dispatching LoginRequested event...');
      context.read<AuthBloc>().add(
            LoginRequested(
              userNameOrEmail: userNameOrEmail,
              password: password,
              rememberMe: _rememberMe,
            ),
          );
      print('🔐 [SignInForm] ✅ LoginRequested event dispatched');
    } else {
      print('🔐 [SignInForm] ❌ Form validation failed');
    }

    print('🔐 [SignInForm] ===== SIGN IN ATTEMPT END =====');
  }

  String? _validateUserNameOrEmail(String? value) {
    print('🔐 [SignInForm] Validating username/email: $value');

    if (value == null || value.trim().isEmpty) {
      print('🔐 [SignInForm] ❌ Username/email is empty');
      return 'Kullanıcı adı veya e-posta gerekli';
    }

    if (value.trim().length < 3) {
      print(
          '🔐 [SignInForm] ❌ Username/email too short: ${value.trim().length}');
      return 'Kullanıcı adı veya e-posta en az 3 karakter olmalı';
    }

    print('🔐 [SignInForm] ✅ Username/email validation passed');
    return null;
  }

  String? _validatePassword(String? value) {
    print(
        '🔐 [SignInForm] Validating password: ${value != null ? '${value.length} chars' : 'null'}');

    if (value == null || value.isEmpty) {
      print('🔐 [SignInForm] ❌ Password is empty');
      return 'Şifre gerekli';
    }

    if (value.length < 6) {
      print('🔐 [SignInForm] ❌ Password too short: ${value.length}');
      return 'Şifre en az 6 karakter olmalı';
    }

    print('🔐 [SignInForm] ✅ Password validation passed');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    print('🔐 [SignInForm] ===== BUILDING SIGN IN FORM =====');

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Username/Email Field
            TextFormField(
              controller: _userNameOrEmailController,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı Adı veya E-posta',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateUserNameOrEmail,
              onChanged: (value) {
                print('🔐 [SignInForm] Username/email changed: $value');
              },
            ),
            const SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Şifre',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    print('🔐 [SignInForm] Password visibility toggled');
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                    print(
                        '🔐 [SignInForm] Password obscured: $_obscurePassword');
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              validator: _validatePassword,
              onChanged: (value) {
                print(
                    '🔐 [SignInForm] Password changed: ${value.length} chars');
              },
              onFieldSubmitted: (_) {
                print('🔐 [SignInForm] Password field submitted');
                _signIn();
              },
            ),
            const SizedBox(height: 16),

            // Remember Me Checkbox
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    print('🔐 [SignInForm] Remember Me changed: $value');
                    setState(() {
                      _rememberMe = value ?? true;
                    });
                    print('🔐 [SignInForm] Remember Me set to: $_rememberMe');
                  },
                ),
                const Text('Beni Hatırla'),
              ],
            ),
            const SizedBox(height: 24),

            // Sign In Button
            ElevatedButton(
              onPressed: () {
                print('🔐 [SignInForm] Sign in button pressed');
                _signIn();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Giriş Yap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // Forgot Password Link
            TextButton(
              onPressed: () {
                print('🔐 [SignInForm] Forgot password pressed');
                // TODO: Implement forgot password
              },
              child: const Text('Şifremi Unuttum'),
            ),
          ],
        ),
      ),
    );
  }
}
