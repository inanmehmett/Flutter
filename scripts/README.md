# Scripts

## update_ip_config.sh

Bu script, `local_config.dart` dosyasındaki IP adresini otomatik olarak bulur ve Android/iOS native konfigürasyon dosyalarını günceller.

### Kullanım

Script otomatik olarak Android build sırasında çalışır. Manuel çalıştırmak için:

```bash
./scripts/update_ip_config.sh
```

### Nasıl Çalışır?

1. `lib/core/config/local_config.dart` dosyasından IP adresini okur
2. Android `network_security_config.xml` dosyasını günceller
3. iOS `Info.plist` dosyasını günceller

### Not

Android ve iOS konfigürasyonları artık tüm HTTP bağlantılarına izin veriyor (`cleartextTrafficPermitted="true"` ve `NSAllowsArbitraryLoads`), bu yüzden IP adresini manuel olarak güncellemeye gerek yok. Ancak bu script, gelecekte daha güvenli bir konfigürasyon kullanmak isterseniz hazır.

