import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isShowing;

  const LoadingOverlay({
    super.key,
    required this.isShowing,
  });

  @override
  Widget build(BuildContext context) {
    if (!isShowing) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
