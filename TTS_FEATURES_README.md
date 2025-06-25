# Gelişmiş Metin Seslendirme (TTS) Özellikleri

Bu proje, kitap okuma sayfasına gelişmiş metin seslendirme özellikleri eklenmiştir. Clean code prensiplerine uygun olarak tasarlanmıştır.

## 🎯 Eklenen Özellikler

### 1. Gelişmiş Speech Manager (`AdvancedSpeechManager`)

- **Temiz Kod Yapısı**: Single Responsibility Principle'a uygun
- **State Management**: TTS durumunu merkezi olarak yönetir
- **Error Handling**: Hata durumlarını düzgün şekilde ele alır
- **Event Handling**: TTS olaylarını dinler ve yönetir

### 2. Kelime Vurgulama (`HighlightedTextView`)

- **Kelime Bazlı Vurgulama**: Okunan kelimeyi vurgular
- **Tap Gesture**: Kelimelere tıklayarak telaffuz edebilme
- **Customizable**: Renk, boyut ve stil özelleştirilebilir

### 3. Gelişmiş Speech Control (`AdvancedSpeechControlView`)

- **Play/Pause/Stop**: Temel kontrol butonları
- **Progress Bar**: Sayfa ilerlemesini gösterir
- **Settings Panel**: Gelişmiş ayarlar için açılır panel
- **Voice Selection**: Farklı ses seçenekleri
- **Speed Control**: Konuşma hızı ayarı (0.1x - 1.0x)
- **Pitch Control**: Ses tonu ayarı (0.5x - 2.0x)
- **Volume Control**: Ses seviyesi ayarı (0% - 100%)
- **Auto-Advance**: Otomatik sayfa geçişi

### 4. Gelişmiş Reader Bloc (`AdvancedReaderBloc`)

- **Clean Architecture**: BLoC pattern kullanımı
- **Event-Driven**: Tüm TTS olayları event'lerle yönetilir
- **State Management**: Uygulama durumu merkezi olarak yönetilir
- **Auto-Advance Timer**: Otomatik ilerleme için timer yönetimi

### 5. Temiz Reader Page (`ReaderPage`)

- **Separation of Concerns**: UI ve logic ayrımı
- **Responsive Design**: Farklı ekran boyutlarına uyumlu
- **Error Handling**: Hata durumları için kullanıcı dostu arayüz
- **Loading States**: Yükleme durumları için uygun UI

## 🚀 Kullanım

### Temel Kullanım

1. Kitap sayfasını açın
2. Alt kısımdaki play butonuna basın
3. Metin seslendirilmeye başlayacak

### Gelişmiş Özellikler

1. **Kelime Telaffuzu**: Herhangi bir kelimeye tıklayın
2. **Hız Ayarı**: Settings panelinden hızı ayarlayın
3. **Ses Tonu**: Pitch ayarını değiştirin
4. **Otomatik İlerleme**: Auto-advance özelliğini aktifleştirin
5. **Ses Seçimi**: Farklı ses seçeneklerini deneyin

## 🏗️ Mimari Yapı

```
lib/
├── core/
│   ├── managers/
│   │   └── advanced_speech_manager.dart    # Gelişmiş TTS yöneticisi
│   └── widgets/
│       └── highlighted_text_view.dart      # Kelime vurgulama widget'ı
├── features/
│   └── reader/
│       └── presentation/
│           ├── bloc/
│           │   ├── advanced_reader_bloc.dart    # Gelişmiş reader bloc
│           │   ├── reader_event.dart            # Event'ler
│           │   └── reader_state.dart            # State'ler
│           ├── pages/
│           │   └── reader_page.dart             # Ana reader sayfası
│           └── widgets/
│               └── advanced_speech_control_view.dart  # TTS kontrol widget'ı
```

## 🔧 Teknik Detaylar

### Event'ler

- `TogglePlayPause`: Oynat/Duraklat
- `StopSpeech`: Durdur
- `UpdateSpeechRate`: Hız güncelle
- `UpdatePitch`: Ton güncelle
- `UpdateVolume`: Ses seviyesi güncelle
- `UpdateVoice`: Ses seçimi güncelle
- `ToggleAutoAdvance`: Otomatik ilerleme
- `SpeakWord`: Kelime telaffuz et

### State'ler

- `ReaderInitial`: Başlangıç durumu
- `ReaderLoading`: Yükleme durumu
- `ReaderError`: Hata durumu
- `ReaderLoaded`: Yüklü durum (TTS bilgileri dahil)

### Özellikler

- **Responsive**: Tüm ekran boyutlarına uyumlu
- **Accessible**: Erişilebilirlik standartlarına uygun
- **Performance**: Optimize edilmiş performans
- **Maintainable**: Kolay bakım yapılabilir kod yapısı

## 🎨 UI/UX Özellikleri

### Renk Paleti

- **Primary**: Material Design 3 renk paleti
- **Highlight**: Sarı vurgulama rengi
- **Background**: Temiz beyaz arka plan
- **Text**: Okunabilir siyah metin

### Animasyonlar

- **Smooth Transitions**: Yumuşak geçişler
- **Loading Indicators**: Yükleme göstergeleri
- **Progress Animations**: İlerleme animasyonları

### Kullanıcı Deneyimi

- **Intuitive Controls**: Sezgisel kontrol butonları
- **Visual Feedback**: Görsel geri bildirimler
- **Error Recovery**: Hata kurtarma mekanizmaları

## 🔮 Gelecek Özellikler

- [ ] Kelime bazlı vurgulama animasyonu
- [ ] Çoklu dil desteği
- [ ] Ses kaydetme özelliği
- [ ] Okuma istatistikleri
- [ ] Sosyal paylaşım özellikleri

## 📝 Notlar

Bu implementasyon clean code prensiplerine uygun olarak tasarlanmıştır:

- **Single Responsibility**: Her sınıf tek bir sorumluluğa sahip
- **Open/Closed**: Genişletilebilir, değiştirilemez
- **Dependency Inversion**: Bağımlılıklar soyutlamalara dayalı
- **Interface Segregation**: Küçük ve odaklanmış arayüzler
- **DRY**: Kod tekrarından kaçınılmış
