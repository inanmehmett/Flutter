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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(AppTheme.light),
      darkTheme: AppTheme.getTheme(AppTheme.dark),
      home: Builder(
        builder: (ctx) => SplashScreen(onComplete: () {
          Navigator.of(ctx).pushReplacementNamed('/home');
        }),
      ),
      routes: {
        '/home': (_) => const Scaffold(body: Center(child: Text('Home Placeholder'))),
      },
    );
  }
}
