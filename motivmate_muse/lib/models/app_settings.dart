

enum BarTiming {
  intervalMinutes,
  timeOfDay,
}

class AppSettings {
  final String themeId;
  final String appLanguage; // tr | en

  // Photo edits
  final double blurSigma; // background blur intensity
  final String photoFilterId; // "none", "sepia", etc.
  final double photoFilterIntensity; // 0.0 to 1.0

  // Card edits
  final bool showCard;
  final bool showCardBackground;
  final double backgroundOverlayOpacity; // overlay over background image
  final double cardOpacity; // card container opacity
  final double cardLeftN; // 0..1 (left edge position, fraction of screen width)
  final double cardTopN; // 0..1 (top edge position, fraction of screen height)
  final double cardWidthN; // 0..1 (card width as fraction of screen width)
  final double cardHeightN; // 0..1 (card height as fraction of screen height)
  final int cardBackgroundColorValue;

  // Text edits
  final double fontSize;
  final int textColorValue;
  final String fontFamily;
  final String textEffectId;

  // Notifications
  final bool barNotificationsEnabled;
  final BarTiming barTiming;
  final int barIntervalMinutes;
  final int barTimeOfDayMinutes;

  const AppSettings({
    required this.themeId,
    required this.appLanguage,
    required this.blurSigma,
    required this.photoFilterId,
    required this.photoFilterIntensity,
    required this.showCard,
    required this.showCardBackground,
    required this.backgroundOverlayOpacity,
    required this.cardOpacity,
    required this.cardLeftN,
    required this.cardTopN,
    required this.cardWidthN,
    required this.cardHeightN,
    required this.cardBackgroundColorValue,
    required this.fontSize,
    required this.textColorValue,
    required this.fontFamily,
    required this.textEffectId,
    required this.barNotificationsEnabled,
    required this.barTiming,
    required this.barIntervalMinutes,
    required this.barTimeOfDayMinutes,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      themeId: 'amethyst',
      appLanguage: 'tr',
      blurSigma: 0,
      photoFilterId: 'none',
      photoFilterIntensity: 1.0,
      showCard: true,
      showCardBackground: true,
      backgroundOverlayOpacity: 0.35,
      cardOpacity: 0.92,
      cardLeftN: 0.05,  // 5% from left
      cardTopN: 0.20,   // 20% from top
      cardWidthN: 0.88, // 88% of screen width — wide enough for any quote
      cardHeightN: 0.38, // 38% of screen height — tall enough for multi-line quotes
      cardBackgroundColorValue: 0xFFFFFFFB,
      fontSize: 22,
      textColorValue: 0xFF2A1B12,
      fontFamily: 'Roboto',
      textEffectId: 'none',
      barNotificationsEnabled: false,
      barTiming: BarTiming.intervalMinutes,
      barIntervalMinutes: 120,
      barTimeOfDayMinutes: 9 * 60,
    );
  }

  AppSettings copyWith({
    String? themeId,
    String? appLanguage,
    double? blurSigma,
    String? photoFilterId,
    double? photoFilterIntensity,
    bool? showCard,
    bool? showCardBackground,
    double? backgroundOverlayOpacity,
    double? cardOpacity,
    double? cardLeftN,
    double? cardTopN,
    double? cardWidthN,
    double? cardHeightN,
    int? cardBackgroundColorValue,
    double? fontSize,
    int? textColorValue,
    String? fontFamily,
    String? textEffectId,
    bool? barNotificationsEnabled,
    BarTiming? barTiming,
    int? barIntervalMinutes,
    int? barTimeOfDayMinutes,
  }) {
    return AppSettings(
      themeId: themeId ?? this.themeId,
      appLanguage: appLanguage ?? this.appLanguage,
      blurSigma: blurSigma ?? this.blurSigma,
      photoFilterId: photoFilterId ?? this.photoFilterId,
      photoFilterIntensity: photoFilterIntensity ?? this.photoFilterIntensity,
      showCard: showCard ?? this.showCard,
      showCardBackground: showCardBackground ?? this.showCardBackground,
      backgroundOverlayOpacity:
          backgroundOverlayOpacity ?? this.backgroundOverlayOpacity,
      cardOpacity: cardOpacity ?? this.cardOpacity,
      cardLeftN: cardLeftN ?? this.cardLeftN,
      cardTopN: cardTopN ?? this.cardTopN,
      cardWidthN: cardWidthN ?? this.cardWidthN,
      cardHeightN: cardHeightN ?? this.cardHeightN,
      cardBackgroundColorValue:
          cardBackgroundColorValue ?? this.cardBackgroundColorValue,
      fontSize: fontSize ?? this.fontSize,
      textColorValue: textColorValue ?? this.textColorValue,
      fontFamily: fontFamily ?? this.fontFamily,
      textEffectId: textEffectId ?? this.textEffectId,
      barNotificationsEnabled:
          barNotificationsEnabled ?? this.barNotificationsEnabled,
      barTiming: barTiming ?? this.barTiming,
      barIntervalMinutes: barIntervalMinutes ?? this.barIntervalMinutes,
      barTimeOfDayMinutes: barTimeOfDayMinutes ?? this.barTimeOfDayMinutes,
    );
  }

  static int _barTimingToJson(BarTiming t) => t.index;
  static BarTiming _barTimingFromJson(int v) => BarTiming.values[v];

  Map<String, Object?> toJson() => {
        'themeId': themeId,
        'appLanguage': appLanguage,
        'blurSigma': blurSigma,
        'photoFilterId': photoFilterId,
        'photoFilterIntensity': photoFilterIntensity,
        'showCard': showCard,
        'showCardBackground': showCardBackground,
        'backgroundOverlayOpacity': backgroundOverlayOpacity,
        'cardOpacity': cardOpacity,
        'cardLeftN': cardLeftN,
        'cardTopN': cardTopN,
        'cardWidthN': cardWidthN,
        'cardHeightN': cardHeightN,
        'cardBackgroundColorValue': cardBackgroundColorValue,
        'fontSize': fontSize,
        'textColorValue': textColorValue,
        'fontFamily': fontFamily,
        'textEffectId': textEffectId,
        'barNotificationsEnabled': barNotificationsEnabled,
        'barTiming': _barTimingToJson(barTiming),
        'barIntervalMinutes': barIntervalMinutes,
        'barTimeOfDayMinutes': barTimeOfDayMinutes,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    return defaults.copyWith(
      themeId: json['themeId'] as String? ?? defaults.themeId,
      appLanguage: json['appLanguage'] as String? ?? defaults.appLanguage,
      blurSigma: (json['blurSigma'] as num?)?.toDouble() ?? defaults.blurSigma,
      photoFilterId:
          json['photoFilterId'] as String? ?? defaults.photoFilterId,
      photoFilterIntensity:
          (json['photoFilterIntensity'] as num?)?.toDouble() ??
              defaults.photoFilterIntensity,
      showCard: json['showCard'] as bool? ?? defaults.showCard,
      showCardBackground:
          json['showCardBackground'] as bool? ?? defaults.showCardBackground,
      backgroundOverlayOpacity:
          (json['backgroundOverlayOpacity'] as num?)?.toDouble() ??
              defaults.backgroundOverlayOpacity,
      cardOpacity:
          (json['cardOpacity'] as num?)?.toDouble() ?? defaults.cardOpacity,
      cardLeftN:
          (json['cardLeftN'] as num?)?.toDouble() ?? defaults.cardLeftN,
      cardTopN: (json['cardTopN'] as num?)?.toDouble() ?? defaults.cardTopN,
      // cardWidthN / cardHeightN: fall back to defaults for old saves that
      // don't have these keys yet (backwards compatible).
      cardWidthN:
          (json['cardWidthN'] as num?)?.toDouble() ?? defaults.cardWidthN,
      cardHeightN:
          (json['cardHeightN'] as num?)?.toDouble() ?? defaults.cardHeightN,
      cardBackgroundColorValue:
          json['cardBackgroundColorValue'] as int? ??
              defaults.cardBackgroundColorValue,
      fontSize:
          (json['fontSize'] as num?)?.toDouble() ?? defaults.fontSize,
      textColorValue:
          json['textColorValue'] as int? ?? defaults.textColorValue,
      fontFamily: json['fontFamily'] as String? ?? defaults.fontFamily,
      textEffectId: json['textEffectId'] as String? ?? defaults.textEffectId,
      barNotificationsEnabled:
          json['barNotificationsEnabled'] as bool? ??
              defaults.barNotificationsEnabled,
      barTiming: json['barTiming'] != null
          ? _barTimingFromJson(json['barTiming'] as int)
          : defaults.barTiming,
      barIntervalMinutes:
          json['barIntervalMinutes'] as int? ?? defaults.barIntervalMinutes,
      barTimeOfDayMinutes: json['barTimeOfDayMinutes'] as int? ??
          defaults.barTimeOfDayMinutes,
    );
  }
}
