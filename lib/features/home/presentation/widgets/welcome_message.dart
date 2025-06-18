import 'package:flutter/material.dart';

class WelcomeMessage extends StatelessWidget {
  final String userName;
  final bool isFirstWelcome;

  const WelcomeMessage({
    super.key,
    required this.userName,
    required this.isFirstWelcome,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        isFirstWelcome
            ? 'Hoş geldin, $userName!'
            : 'Tekrar hoş geldin, $userName!',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
