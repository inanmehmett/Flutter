import 'dart:io';

/// IP adresi validasyon ve kontrol utility'si
class IpValidator {
  /// IPv4 adres formatını kontrol eder
  /// 
  /// Geçerli format: xxx.xxx.xxx.xxx (her bölüm 0-255 arası)
  static bool isValidIPv4(String ip) {
    if (ip.isEmpty) return false;
    
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return false;
      }
    }
    
    return true;
  }
  
  /// URL'den IP adresini çıkarır ve kontrol eder
  /// 
  /// Örnek: 'http://192.168.1.103:5001' -> '192.168.1.103'
  static String? extractIPFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      
      // localhost, 127.0.0.1 gibi özel adresleri de kontrol et
      if (host == 'localhost' || host == '127.0.0.1') {
        return host;
      }
      
      // IPv4 formatında mı kontrol et
      if (isValidIPv4(host)) {
        return host;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// URL'den IP adresini çıkarır ve geçerliliğini kontrol eder
  static bool isValidIPInUrl(String url) {
    final ip = extractIPFromUrl(url);
    return ip != null && (ip == 'localhost' || ip == '127.0.0.1' || isValidIPv4(ip));
  }
  
  /// IP adresinin erişilebilir olup olmadığını kontrol eder (ping testi)
  /// 
  /// Not: Bu işlem zaman alabilir, async olarak çalışır
  static Future<bool> isReachable(String ip, {int port = 5001, Duration timeout = const Duration(seconds: 3)}) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: timeout);
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// URL'nin erişilebilir olup olmadığını kontrol eder
  static Future<bool> isUrlReachable(String url, {Duration timeout = const Duration(seconds: 3)}) async {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      final port = uri.port != 0 ? uri.port : (uri.scheme == 'https' ? 443 : 80);
      
      // localhost ve 127.0.0.1 için özel kontrol
      if (host == 'localhost' || host == '127.0.0.1') {
        return await isReachable('127.0.0.1', port: port, timeout: timeout);
      }
      
      if (isValidIPv4(host)) {
        return await isReachable(host, port: port, timeout: timeout);
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// IP adresi bilgilerini detaylı olarak kontrol eder ve sonuç döner
  static Future<IpValidationResult> validateIP(String url) async {
    final ip = extractIPFromUrl(url);
    
    if (ip == null) {
      return IpValidationResult(
        isValid: false,
        ip: null,
        message: 'URL\'den IP adresi çıkarılamadı',
        isReachable: false,
      );
    }
    
    final isValid = ip == 'localhost' || ip == '127.0.0.1' || isValidIPv4(ip);
    
    if (!isValid) {
      return IpValidationResult(
        isValid: false,
        ip: ip,
        message: 'IP adresi formatı geçersiz',
        isReachable: false,
      );
    }
    
    // Erişilebilirlik kontrolü
    final reachable = await isUrlReachable(url);
    
    return IpValidationResult(
      isValid: true,
      ip: ip,
      message: reachable ? 'IP adresi geçerli ve erişilebilir' : 'IP adresi geçerli ancak erişilemiyor',
      isReachable: reachable,
    );
  }
}

/// IP validasyon sonucu
class IpValidationResult {
  final bool isValid;
  final String? ip;
  final String message;
  final bool isReachable;
  
  IpValidationResult({
    required this.isValid,
    required this.ip,
    required this.message,
    required this.isReachable,
  });
  
  @override
  String toString() {
    return 'IP: $ip, Geçerli: $isValid, Erişilebilir: $isReachable, Mesaj: $message';
  }
}

