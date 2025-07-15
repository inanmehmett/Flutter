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
                _showForgotPasswordDialog();
              },
              child: const Text('Şifremi Unuttum'),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Şifremi Unuttum'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Lütfen kayıtlı e-posta adresinizi giriniz. Şifre sıfırlama linki size gönderilecektir.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-posta Adresi',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'E-posta adresi gerekli';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Geçerli bir e-posta adresi giriniz';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('İptal'),
                  onPressed: isLoading ? null : () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Gönder'),
                  onPressed: isLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      
                      try {
                        // Call the auth service to reset password
                        final authService = context.read<AuthBloc>().authService;
                        final success = await authService.resetPassword(email: emailController.text.trim());
                        
                        if (success) {
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Şifre sıfırlama linki e-posta adresinize gönderildi.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          throw Exception('Şifre sıfırlama işlemi başarısız oldu.');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
