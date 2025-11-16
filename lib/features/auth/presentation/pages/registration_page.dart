import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;
import '../../../../core/config/app_config.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/loading_overlay.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            RegisterRequested(
              email: _emailController.text.trim(),
              userName: _userNameController.text.trim(),
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
            ),
          );
    }
  }

  Future<void> _googleRegister() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? AppConfig.googleClientId : null,
        serverClientId: AppConfig.googleWebClientId,
        scopes: const ['email', 'profile', 'openid'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) return; // cancelled
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in failed: no idToken')),
        );
        return;
      }
      // Google login - AuthBloc event'i kullan (normal login gibi)
      context.read<AuthBloc>().add(GoogleLoginRequested(idToken: idToken));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Registration/Login başarılı olduğunda home'a yönlendir
        // SignalR AppShell'de zaten başlatılıyor, burada tekrar başlatmaya gerek yok
        if (state is AuthAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            
            // Home'a yönlendir (SignalR AppShell'de başlatılacak)
            Navigator.of(context).pushReplacementNamed('/home');
          });
        } else if (state is AuthErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF8F8FA),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Üst turuncu alan ve ikon
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  padding: EdgeInsets.only(top: 32, bottom: 24),
                  child: Column(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          Platform.isIOS 
                            ? 'assets/icons/AppIcons/Assets.xcassets/AppIcon.appiconset/120.png'
                            : 'assets/icons/AppIcons/android/mipmap-xxhdpi/ic_launcher.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          cacheWidth: 160, // Load at 2x resolution for better quality
                          cacheHeight: 160,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.menu_book, color: Colors.white, size: 48),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 12),
                      Text('KAYIT OL', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 8),
                      Text(
                        'Daily English hesabı oluşturmak için aşağıdaki alanları doldur.',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                // Inputlar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _RoundedInputField(
                          controller: _userNameController,
                          hintText: 'Kullanıcı adı',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen bir kullanıcı adı girin';
                            }
                            if (value.length < 3) {
                              return 'Kullanıcı adı en az 3 karakter olmalı';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 18),
                        _RoundedInputField(
                          controller: _emailController,
                          hintText: 'E‑posta adresi',
                          icon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen bir e‑posta adresi girin';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Lütfen geçerli bir e‑posta adresi girin';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 18),
                        _RoundedInputField(
                          controller: _passwordController,
                          hintText: 'Şifre',
                          icon: Icons.visibility_off_outlined,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onTogglePassword: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen bir şifre girin';
                            }
                            if (value.length < 6) {
                              return 'Şifre en az 6 karakter olmalı';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 18),
                        _RoundedInputField(
                          controller: _confirmPasswordController,
                          hintText: 'Şifreyi tekrar gir',
                          icon: Icons.visibility_off_outlined,
                          isPassword: true,
                          obscureText: _obscureConfirmPassword,
                          onTogglePassword: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen şifrenizi tekrar girin';
                            }
                            if (value != _passwordController.text) {
                              return 'Şifreler eşleşmiyor';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Devam ederek ',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                    children: [
                                      TextSpan(
                                        text: 'Kullanım Koşulları',
                                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(text: 'nı kabul etmiş olursun.'),
                                    ],
                                  ),
                                ),
                          ),
                        ),
                        SizedBox(height: 18),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: state is AuthLoading ? null : _register,
                                    child: state is AuthLoading
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text('KAYDI TAMAMLA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                                SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed: state is AuthLoading ? null : _googleRegister,
                                    icon: Icon(Icons.g_mobiledata, color: Colors.redAccent),
                                    label: const Text('Google ile devam et'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Zaten hesabın var mı? ', style: TextStyle(color: Colors.grey[700], fontSize: 15)),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: const Text('GİRİŞ YAP', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundedInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final String? Function(String?)? validator;
  final VoidCallback? onTogglePassword;

  const _RoundedInputField({
    this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.validator,
    this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.orange),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.orange,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: Color(0xFFF3F3F7),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
