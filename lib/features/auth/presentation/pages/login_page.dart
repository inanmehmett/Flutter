import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userNameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _userNameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginRequested(
              userNameOrEmail: _userNameOrEmailController.text.trim(),
              password: _passwordController.text,
              rememberMe: true,
            ),
          );
    }
  }

  Future<void> _googleLogin() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? AppConfig.googleClientId : null, // iOS: iOS Client ID, Android: null
        serverClientId: AppConfig.googleWebClientId,                // Android/iOS: Web Client ID for idToken
        scopes: const ['email','profile','openid'],
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
      // googleLogin() zaten UserProfile döndürüyor, AuthBloc bunu handle edecek
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
        // Login başarılı olduğunda home'a yönlendir
        // SignalR AppShell'de zaten başlatılıyor, burada tekrar başlatmaya gerek yok
        if (state is AuthAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            
            // Home'a yönlendir (SignalR AppShell'de başlatılacak)
            Navigator.of(context).pushReplacementNamed('/home');
          });
        } 
        // Login hatası durumunda kullanıcıyı bilgilendir
        else if (state is AuthErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                // Üst turuncu alan ve ikon
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
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
                      Text('GİRİŞ YAP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 8),
                      Text(
                        'Kaldığın yerden devam etmek için hesabına giriş yap.',
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
                        controller: _userNameOrEmailController,
                        hintText: 'Kullanıcı adı veya e‑posta',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen kullanıcı adı veya e‑posta girin';
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
                            return 'Lütfen şifrenizi girin';
                          }
                          if (value.length < 6) {
                            return 'Şifre en az 6 karakter olmalı';
                          }
                          return null;
                        },
                        suffix: Align(
                          alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // TODO: Şifre sıfırlama eklenecek
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Şifre sıfırlama özelliği yakında eklenecek.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                              child: const Text(
                                'Şifreni mi unuttun?',
                                style: TextStyle(color: Colors.orange, fontSize: 13),
                              ),
                            ),
                        ),
                      ),
                      SizedBox(height: 32),
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
                                  onPressed: state is AuthLoading ? null : _login,
                                  child: state is AuthLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text('DEVAM ET', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                                    onPressed: state is AuthLoading ? null : _googleLogin,
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
                          Text('Daily English\'e yeni misin? ', style: TextStyle(color: Colors.grey[700], fontSize: 15)),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: const Text('KAYIT OL', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ],
                      ),
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
  final Widget? suffix;
  final String? Function(String?)? validator;
  final VoidCallback? onTogglePassword;

  const _RoundedInputField({
    this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.suffix,
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
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.primary,
                ),
                onPressed: onTogglePassword,
              )
            : suffix,
        filled: true,
        fillColor: AppColors.surfaceSecondary,
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
