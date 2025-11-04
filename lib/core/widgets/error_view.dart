import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../error/app_error.dart';

/// Standard error display widget with retry functionality.
/// 
/// Features:
/// - User-friendly error messages
/// - Error-specific icons
/// - Retry button
/// - Responsive design
/// 
/// Example:
/// ```dart
/// ErrorView(
///   error: NetworkError.noInternet(),
///   onRetry: () => _loadData(),
/// )
/// ```
class ErrorView extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final bool showRetry;
  final EdgeInsets padding;

  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.showRetry = true,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildErrorIcon(),
            const SizedBox(height: 16),
            _buildErrorMessage(context),
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: 24),
              _buildRetryButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    IconData icon;
    Color color;

    if (error is NetworkError) {
      icon = Icons.wifi_off_rounded;
      color = Colors.orange;
    } else if (error is AuthError) {
      icon = Icons.lock_outline_rounded;
      color = Colors.red.shade400;
    } else if (error is NotFoundError) {
      icon = Icons.search_off_rounded;
      color = Colors.grey.shade600;
    } else if (error is ValidationError) {
      icon = Icons.warning_amber_rounded;
      color = Colors.amber;
    } else {
      icon = Icons.error_outline_rounded;
      color = Colors.red.shade400;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 48,
        color: color,
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Column(
      children: [
        Text(
          error.message,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        if (error.code != null) ...[
          const SizedBox(height: 8),
          Text(
            'Hata Kodu: ${error.code}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded, size: 20),
      label: const Text('Tekrar Dene'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Compact error view for inline display
class CompactErrorView extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const CompactErrorView({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              color: Colors.red.shade400,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

