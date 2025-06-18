import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';

extension ViewModifiers on Widget {
  Widget cornerRadius(double radius,
      {List<Corner> corners = const [Corner.all]}) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: corners.contains(Corner.topLeft)
            ? Radius.circular(radius)
            : Radius.zero,
        topRight: corners.contains(Corner.topRight)
            ? Radius.circular(radius)
            : Radius.zero,
        bottomLeft: corners.contains(Corner.bottomLeft)
            ? Radius.circular(radius)
            : Radius.zero,
        bottomRight: corners.contains(Corner.bottomRight)
            ? Radius.circular(radius)
            : Radius.zero,
      ),
      child: this,
    );
  }

  Widget withErrorHandling(ValueNotifier<Exception?> error) {
    return Stack(
      children: [
        this,
        if (error.value != null)
          AlertDialog(
            title: const Text('Error'),
            content: Text(error.value?.toString() ?? 'Unknown error occurred'),
            actions: [
              TextButton(
                onPressed: () => error.value = null,
                child: const Text('OK'),
              ),
            ],
          ),
      ],
    );
  }

  Widget withLoadingIndicator(bool isLoading) {
    return Stack(
      children: [
        this,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget withTheme() {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final theme = Theme.of(context);
        return Container(
          color: theme.colorScheme.surface,
          child: DefaultTextStyle(
            style: TextStyle(color: theme.colorScheme.onSurface),
            child: this,
          ),
        );
      },
    );
  }
}

enum Corner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  all,
}
