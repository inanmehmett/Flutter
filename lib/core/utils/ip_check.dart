import 'ip_validator.dart';
import '../config/local_config.dart';

/// IP adresi kontrolü yapar ve sonuçları gösterir
class IpChecker {
  /// LocalConfig'deki IP adresini kontrol eder
  static Future<void> checkLocalConfigIP() async {
    print('🔍 IP Adresi Kontrolü Başlatılıyor...\n');
    print('📍 URL: ${LocalConfig.lanBaseUrl}\n');
    
    final result = await IpValidator.validateIP(LocalConfig.lanBaseUrl);
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 Kontrol Sonuçları:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('IP Adresi: ${result.ip ?? "Bulunamadı"}');
    print('Format Geçerli: ${result.isValid ? "✅ Evet" : "❌ Hayır"}');
    print('Erişilebilir: ${result.isReachable ? "✅ Evet" : "❌ Hayır"}');
    print('Durum: ${result.message}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    if (!result.isValid) {
      print('⚠️  UYARI: IP adresi formatı geçersiz!');
      print('   Lütfen local_config.dart dosyasındaki IP adresini kontrol edin.\n');
    } else if (!result.isReachable) {
      print('⚠️  UYARI: IP adresine erişilemiyor!');
      print('   Olası nedenler:');
      print('   - Backend sunucusu çalışmıyor olabilir');
      print('   - IP adresi değişmiş olabilir');
      print('   - Ağ bağlantısı yok olabilir');
      print('   - Firewall engellemesi olabilir\n');
    } else {
      print('✅ IP adresi geçerli ve erişilebilir!\n');
    }
  }
  
  /// Hızlı format kontrolü (erişilebilirlik kontrolü yapmadan)
  static void quickCheck() {
    print('🔍 Hızlı IP Format Kontrolü\n');
    print('📍 URL: ${LocalConfig.lanBaseUrl}');
    
    final ip = IpValidator.extractIPFromUrl(LocalConfig.lanBaseUrl);
    final isValid = IpValidator.isValidIPInUrl(LocalConfig.lanBaseUrl);
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('IP Adresi: ${ip ?? "Bulunamadı"}');
    print('Format Geçerli: ${isValid ? "✅ Evet" : "❌ Hayır"}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }
}

