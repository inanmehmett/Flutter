import '../config/app_config.dart';

/// Centralized URL normalization utility
/// Normalizes image URLs by replacing localhost, 127.0.0.1, and old IP addresses
/// with the current API base URL
class UrlNormalizer {
  /// Normalize an image URL to use the current API base URL
  /// 
  /// Handles:
  /// - Full URLs with localhost/127.0.0.1/old IP addresses
  /// - Relative paths (with or without leading slash)
  /// - file:// protocol URLs
  /// - External URLs (returns as-is)
  static String? normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // If already a full URL, check if it needs normalization
    if (url.startsWith('http://') || url.startsWith('https://')) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final host = uri.host;
        // Replace localhost, 127.0.0.1, or old IP addresses with current base URL
        if (_shouldReplaceHost(host)) {
          final path = uri.path;
          final query = uri.query.isNotEmpty ? '?${uri.query}' : '';
          return '${AppConfig.apiBaseUrl}$path$query';
        }
      }
      // Valid external URL, return as-is
      return url;
    }
    
    // Handle file:// protocol
    if (url.startsWith('file://')) {
      return url.replaceFirst('file://', AppConfig.apiBaseUrl);
    }
    
    // Relative path - combine with base URL
    if (url.startsWith('/')) {
      return '${AppConfig.apiBaseUrl}$url';
    }
    return '${AppConfig.apiBaseUrl}/$url';
  }
  
  /// Check if host should be replaced with current API base URL
  static bool _shouldReplaceHost(String host) {
    return host == 'localhost' ||
           host == '127.0.0.1' ||
           host.startsWith('192.168.') ||
           host.startsWith('10.0.2.2');
  }
}

