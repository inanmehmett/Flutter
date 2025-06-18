import '../theme/app_theme.dart';
import '../theme/font_type.dart';

class AppSettings {
  final AppTheme theme;
  final double fontSize;
  final FontType fontType;
  final double speechRate;
  final bool autoPlayEnabled;
  final String? preferredVoiceId;
  final double voicePitch;
  final String? preferredVoiceGender;

  const AppSettings({
    this.theme = AppTheme.light,
    this.fontSize = 16.0,
    this.fontType = FontType.systemRegular,
    this.speechRate = 0.5,
    this.autoPlayEnabled = false,
    this.preferredVoiceId,
    this.voicePitch = 1.0,
    this.preferredVoiceGender,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      theme: AppTheme.values[json['theme'] as int],
      fontSize: json['fontSize'] as double,
      fontType: FontType.values[json['fontType'] as int],
      speechRate: json['speechRate'] as double,
      autoPlayEnabled: json['autoPlayEnabled'] as bool,
      preferredVoiceId: json['preferredVoiceId'] as String?,
      voicePitch: json['voicePitch'] as double,
      preferredVoiceGender: json['preferredVoiceGender'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme.index,
      'fontSize': fontSize,
      'fontType': fontType.index,
      'speechRate': speechRate,
      'autoPlayEnabled': autoPlayEnabled,
      'preferredVoiceId': preferredVoiceId,
      'voicePitch': voicePitch,
      'preferredVoiceGender': preferredVoiceGender,
    };
  }

  AppSettings copyWith({
    AppTheme? theme,
    double? fontSize,
    FontType? fontType,
    double? speechRate,
    bool? autoPlayEnabled,
    String? preferredVoiceId,
    double? voicePitch,
    String? preferredVoiceGender,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      fontType: fontType ?? this.fontType,
      speechRate: speechRate ?? this.speechRate,
      autoPlayEnabled: autoPlayEnabled ?? this.autoPlayEnabled,
      preferredVoiceId: preferredVoiceId ?? this.preferredVoiceId,
      voicePitch: voicePitch ?? this.voicePitch,
      preferredVoiceGender: preferredVoiceGender ?? this.preferredVoiceGender,
    );
  }
}
