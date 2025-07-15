import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../onboarding/presentation/widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily English',
      theme: AppTheme.getTheme(AppTheme.light),
      darkTheme: AppTheme.getTheme(AppTheme.dark),
      home: SplashScreen(onComplete: () {
        Navigator.of(context).pushReplacementNamed('/home');
      }),
    );
  }
}
