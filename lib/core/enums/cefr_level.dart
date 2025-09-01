/// CEFR (Common European Framework of Reference for Languages) seviyeleri
/// Uluslararası dil seviyesi standardı
enum CefrLevel {
  /// A1 - Başlangıç (Beginner)
  /// Temel kelimeler ve basit cümleler
  a1(1, 'A1', 'Başlangıç', 'Beginner', '🌱', '#3498db'),
  
  /// A2 - Temel (Elementary)
  /// Günlük konuşma ve basit metinler
  a2(2, 'A2', 'Temel', 'Elementary', '🌿', '#27ae60'),
  
  /// B1 - Orta (Intermediate)
  /// Orta seviye konuşma ve yazma
  b1(3, 'B1', 'Orta', 'Intermediate', '🌼', '#e67e22'),
  
  /// B2 - İleri Orta (Upper-Intermediate)
  /// İleri orta seviye iletişim
  b2(4, 'B2', 'İleri Orta', 'Upper-Intermediate', '🍀', '#9b59b6'),
  
  /// C1 - İleri (Advanced)
  /// İleri seviye dil kullanımı
  c1(5, 'C1', 'İleri', 'Advanced', '🌟', '#f1c40f'),
  
  /// C2 - Usta (Proficient)
  /// Ana dil seviyesinde yeterlilik
  c2(6, 'C2', 'Usta', 'Proficient', '🏆', '#e74c3c');

  const CefrLevel(this.value, this.code, this.turkishName, this.englishName, this.icon, this.color);

  final int value;
  final String code;
  final String turkishName;
  final String englishName;
  final String icon;
  final String color;

  /// CEFR seviyesinin açıklamasını döndürür
  String get description {
    switch (this) {
      case CefrLevel.a1:
        return 'Temel kelimeler ve basit cümleler kullanabilir';
      case CefrLevel.a2:
        return 'Günlük konuşma ve basit metinler anlayabilir';
      case CefrLevel.b1:
        return 'Orta seviye konuşma ve yazma yapabilir';
      case CefrLevel.b2:
        return 'İleri orta seviye iletişim kurabilir';
      case CefrLevel.c1:
        return 'İleri seviye dil kullanımı yapabilir';
      case CefrLevel.c2:
        return 'Ana dil seviyesinde yeterlilik gösterir';
    }
  }

  /// CEFR seviyesinin XP aralığını döndürür (Profesyonel sistem)
  (int minXP, int maxXP) get xpRange {
    switch (this) {
      case CefrLevel.a1:
        return (0, 2999); // A1.1: 0-799, A1.2: 800-1799, A1.3: 1800-2999
      case CefrLevel.a2:
        return (3000, 11999); // A2.1: 3000-4999, A2.2: 5000-7999, A2.3: 8000-11999
      case CefrLevel.b1:
        return (12000, 34999); // B1.1: 12000-17999, B1.2: 18000-24999, B1.3: 25000-34999
      case CefrLevel.b2:
        return (35000, 89999); // B2.1: 35000-49999, B2.2: 50000-69999, B2.3: 70000-89999
      case CefrLevel.c1:
        return (90000, 199999); // C1.1: 90000-119999, C1.2: 120000-159999, C1.3: 160000-199999
      case CefrLevel.c2:
        return (200000, 999999); // C2.1: 200000-249999, C2.2: 250000-349999, C2.3: 350000-999999
    }
  }

  /// XP'den CEFR seviyesini hesaplar
  static CefrLevel fromXP(int xp) {
    if (xp < 3000) return CefrLevel.a1;
    if (xp < 12000) return CefrLevel.a2;
    if (xp < 35000) return CefrLevel.b1;
    if (xp < 90000) return CefrLevel.b2;
    if (xp < 200000) return CefrLevel.c1;
    return CefrLevel.c2;
  }

  /// CEFR seviyesinin alt seviyesini hesaplar (1, 2, 3)
  int getSubLevel(int xp) {
    final (minXP, maxXP) = xpRange;
    final levelXP = xp - minXP;
    final levelRange = maxXP - minXP;
    
    if (levelXP < levelRange / 3) return 1;
    if (levelXP < (levelRange * 2) / 3) return 2;
    return 3;
  }

  /// Tam seviye adını döndürür (örn: "A1.2", "B2.3")
  String getFullLevelName(int xp) {
    final subLevel = getSubLevel(xp);
    return '$code.$subLevel';
  }

  /// Türkçe tam seviye adını döndürür (örn: "A1.2 - Temel")
  String getFullTurkishName(int xp) {
    final subLevel = getSubLevel(xp);
    return '$code.$subLevel - $turkishName';
  }

  /// İngilizce tam seviye adını döndürür (örn: "A1.2 - Beginner")
  String getFullEnglishName(int xp) {
    final subLevel = getSubLevel(xp);
    return '$code.$subLevel - $englishName';
  }

  /// Bir sonraki seviyeye kadar olan XP'yi hesaplar
  int getXPToNextLevel(int currentXP) {
    final (_, maxXP) = xpRange;
    return maxXP - currentXP;
  }

  /// Mevcut seviye içindeki ilerlemeyi yüzde olarak hesaplar
  double getProgressInLevel(int currentXP) {
    final (minXP, maxXP) = xpRange;
    final levelXP = currentXP - minXP;
    final levelRange = maxXP - minXP;
    return (levelXP / levelRange).clamp(0.0, 1.0);
  }

  /// Bir sonraki alt seviyeye kadar olan XP'yi hesaplar
  int getXPToNextSubLevel(int currentXP) {
    final (minXP, maxXP) = xpRange;
    final levelXP = currentXP - minXP;
    final levelRange = maxXP - minXP;
    final subLevelRange = levelRange / 3;
    
    final currentSubLevel = getSubLevel(currentXP);
    final nextSubLevelXP = (currentSubLevel * subLevelRange).toInt();
    
    return nextSubLevelXP - levelXP;
  }

  /// Mevcut alt seviye içindeki ilerlemeyi yüzde olarak hesaplar
  double getProgressInSubLevel(int currentXP) {
    final (minXP, maxXP) = xpRange;
    final levelXP = currentXP - minXP;
    final levelRange = maxXP - minXP;
    final subLevelRange = levelRange / 3;
    
    final currentSubLevel = getSubLevel(currentXP);
    final subLevelStartXP = ((currentSubLevel - 1) * subLevelRange).toInt();
    final subLevelCurrentXP = levelXP - subLevelStartXP;
    
    return (subLevelCurrentXP / subLevelRange).clamp(0.0, 1.0);
  }
}
