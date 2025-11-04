import 'package:flutter/material.dart';
import 'app_error.dart';

/// Global error handler service for consistent error handling across the app.
/// 
/// Features:
/// - Centralized error logging
/// - Error reporting
/// - User notification
/// 
/// Usage:
/// ```dart
/// try {
///   await someOperation();
/// } catch (e) {
///   ErrorHandler.handle(e, context);
/// }
/// ```
class ErrorHandler {
  /// Handle error globally with optional UI feedback
  static void handle(
    dynamic error, 
    BuildContext? context, {
    bool showSnackBar = true,
    VoidCallback? onRetry,
  }) {
    final appError = parseError(error);
    
    // Log error
    _logError(appError);
    
    // Show UI feedback
    if (context != null && showSnackBar) {
      _showErrorSnackBar(context, appError, onRetry);
    }
  }

  /// Log error for debugging
  static void _logError(AppError error) {
    debugPrint('❌ [Error] ${error.code}: ${error.message}');
    if (error.originalError != null) {
      debugPrint('   Original: ${error.originalError}');
    }
  }

  /// Show error as SnackBar
  static void _showErrorSnackBar(
    BuildContext context,
    AppError error,
    VoidCallback? onRetry,
  ) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getErrorIcon(error),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _getErrorColor(error),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      action: onRetry != null
          ? SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Get icon based on error type
  static IconData _getErrorIcon(AppError error) {
    if (error is NetworkError) return Icons.wifi_off_rounded;
    if (error is AuthError) return Icons.lock_outline_rounded;
    if (error is NotFoundError) return Icons.search_off_rounded;
    if (error is ValidationError) return Icons.warning_amber_rounded;
    return Icons.error_outline_rounded;
  }

  /// Get color based on error type
  static Color _getErrorColor(AppError error) {
    if (error is NetworkError) return Colors.orange.shade700;
    if (error is AuthError) return Colors.red.shade700;
    if (error is NotFoundError) return Colors.grey.shade700;
    if (error is ValidationError) return Colors.amber.shade700;
    return Colors.red.shade700;
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          _getErrorIcon(error),
          color: _getErrorColor(error),
          size: 48,
        ),
        title: const Text(
          'Hata',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          error.message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Tekrar Dene'),
            ),
        ],
      ),
    );
  }
}

