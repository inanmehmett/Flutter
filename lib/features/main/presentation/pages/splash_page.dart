import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart' as auth;

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    print('🎨 SplashPage initialized');
    _checkAuthAfterDelay();
  }

  Future<void> _checkAuthAfterDelay() async {
    print('⏳ Waiting 2 seconds before checking auth...');
    await Future.delayed(const Duration(seconds: 2));
    print('🔍 Checking auth status...');
    if (mounted) {
      context.read<auth.AuthBloc>().add(auth.CheckAuthStatus());
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building SplashPage...');
    return BlocListener<auth.AuthBloc, auth.AuthState>(
      listener: (context, authState) {
        print('🔐 AuthBloc state changed: $authState');
        if (authState is auth.AuthAuthenticated) {
          print('✅ User authenticated, navigating to home');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else if (authState is auth.AuthUnauthenticated) {
          print('❌ User not authenticated, navigating to login');
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Builder(
                builder: (context) {
                  print('🖼️ Loading logo...');
                  return Icon(
                    Icons.school,
                    size: 120,
                    color: Theme.of(context).primaryColor,
                  );
                },
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
