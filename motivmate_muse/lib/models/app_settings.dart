enum BarTiming {
  intervalMinutes,
  timeOfDay,
}

// Popup zamanlaması için gerekli olan Enum eklendi
enum PopupTiming {
  immediate,
  timeOfDay,
  betweenHours,
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
  final int effectColorValue;
  final String fontFamily;
  final String textEffectId;

  // Notifications
  final bool barNotificationsEnabled;
  final BarTiming barTiming;
  final int barIntervalMinutes;
  final int barTimeOfDayMinutes;

  // --- YENİ EKLENEN POPUP (AÇILIŞ KARTI) DEĞİŞKENLERİ ---
  final bool popupOnOpenEnabled;
  final PopupTiming popupTiming;
  final int popupTimeOfDayMinutes;
  final int popupBetweenStartMinutes;
  final int popupBetweenEndMinutes;

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
    required this.effectColorValue,
    required this.fontFamily,
    required this.textEffectId,
    required this.barNotificationsEnabled,
    required this.barTiming,
    required this.barIntervalMinutes,
    required this.barTimeOfDayMinutes,
    required this.popupOnOpenEnabled,
    required this.popupTiming,
    required this.popupTimeOfDayMinutes,
    required this.popupBetweenStartMinutes,
    required this.popupBetweenEndMinutes,
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
      cardOpacity: 0.6,
      cardLeftN: 0.06,  // Perfectly centered horizontally: (1.0 - 0.88)/2
      cardTopN: 0.32,   // Perfectly centered vertically: (1.0 - 0.36)/2
      cardWidthN: 0.88, // 88% of screen width
      cardHeightN: 0.36, // 36% of screen height
      cardBackgroundColorValue: 0xFFFFFFFB,
      fontSize: 22,
      textColorValue: 0xFF2A1B12,
      effectColorValue: 0xFF000000,
      fontFamily: 'Open Sans',
      textEffectId: 'none',
      barNotificationsEnabled: false,
      barTiming: BarTiming.intervalMinutes,
      barIntervalMinutes: 120,
      barTimeOfDayMinutes: 9 * 60,
      
      // Popup default değerleri
      popupOnOpenEnabled: true,
      popupTiming: PopupTiming.immediate,
      popupTimeOfDayMinutes: 9 * 60, // 09:00
      popupBetweenStartMinutes: 8 * 60, // 08:00
      popupBetweenEndMinutes: 22 * 60, // 22:00
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
    int? effectColorValue,
    String? fontFamily,
    String? textEffectId,
    bool? barNotificationsEnabled,
    BarTiming? barTiming,
    int? barIntervalMinutes,
    int? barTimeOfDayMinutes,
    bool? popupOnOpenEnabled,
    PopupTiming? popupTiming,
    int? popupTimeOfDayMinutes,
    int? popupBetweenStartMinutes,
    int? popupBetweenEndMinutes,
  }) {
    return AppSettings(
      themeId: themeId ?? this.themeId,
      appLanguage: appLanguage ?? this.appLanguage,
      blurSigma: blurSigma ?? this.blurSigma,
      photoFilterId: photoFilterId ?? this.photoFilterId,
      photoFilterIntensity: photoFilterIntensity ?? this.photoFilterIntensity,
      showCard: showCard ?? this.showCard,
      showCardBackground: showCardBackground ?? this.showCardBackground,
      backgroundOverlayOpacity: backgroundOverlayOpacity ?? this.backgroundOverlayOpacity,
      cardOpacity: cardOpacity ?? this.cardOpacity,
      cardLeftN: cardLeftN ?? this.cardLeftN,
      cardTopN: cardTopN ?? this.cardTopN,
      cardWidthN: cardWidthN ?? this.cardWidthN,
      cardHeightN: cardHeightN ?? this.cardHeightN,
      cardBackgroundColorValue: cardBackgroundColorValue ?? this.cardBackgroundColorValue,
      fontSize: fontSize ?? this.fontSize,
      textColorValue: textColorValue ?? this.textColorValue,
      effectColorValue: effectColorValue ?? this.effectColorValue,
      fontFamily: fontFamily ?? this.fontFamily,
      textEffectId: textEffectId ?? this.textEffectId,
      barNotificationsEnabled: barNotificationsEnabled ?? this.barNotificationsEnabled,
      barTiming: barTiming ?? this.barTiming,
      barIntervalMinutes: barIntervalMinutes ?? this.barIntervalMinutes,
      barTimeOfDayMinutes: barTimeOfDayMinutes ?? this.barTimeOfDayMinutes,
      popupOnOpenEnabled: popupOnOpenEnabled ?? this.popupOnOpenEnabled,
      popupTiming: popupTiming ?? this.popupTiming,
      popupTimeOfDayMinutes: popupTimeOfDayMinutes ?? this.popupTimeOfDayMinutes,
      popupBetweenStartMinutes: popupBetweenStartMinutes ?? this.popupBetweenStartMinutes,
      popupBetweenEndMinutes: popupBetweenEndMinutes ?? this.popupBetweenEndMinutes,
    );
  }

  static int _barTimingToJson(BarTiming t) => t.index;
  static BarTiming _barTimingFromJson(int v) => BarTiming.values[v];

  static int _popupTimingToJson(PopupTiming t) => t.index;
  static PopupTiming _popupTimingFromJson(int v) => PopupTiming.values[v];

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
        'effectColorValue': effectColorValue,
        'fontFamily': fontFamily,
        'textEffectId': textEffectId,
        'barNotificationsEnabled': barNotificationsEnabled,
        'barTiming': _barTimingToJson(barTiming),
        'barIntervalMinutes': barIntervalMinutes,
        'barTimeOfDayMinutes': barTimeOfDayMinutes,
        'popupOnOpenEnabled': popupOnOpenEnabled,
        'popupTiming': _popupTimingToJson(popupTiming),
        'popupTimeOfDayMinutes': popupTimeOfDayMinutes,
        'popupBetweenStartMinutes': popupBetweenStartMinutes,
        'popupBetweenEndMinutes': popupBetweenEndMinutes,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    return defaults.copyWith(
      themeId: json['themeId'] as String? ?? defaults.themeId,
      appLanguage: json['appLanguage'] as String? ?? defaults.appLanguage,
      blurSigma: (json['blurSigma'] as num?)?.toDouble() ?? defaults.blurSigma,
      photoFilterId: json['photoFilterId'] as String? ?? defaults.photoFilterId,
      photoFilterIntensity: (json['photoFilterIntensity'] as num?)?.toDouble() ?? defaults.photoFilterIntensity,
      showCard: json['showCard'] as bool? ?? defaults.showCard,
      showCardBackground: json['showCardBackground'] as bool? ?? defaults.showCardBackground,
      backgroundOverlayOpacity: (json['backgroundOverlayOpacity'] as num?)?.toDouble() ?? defaults.backgroundOverlayOpacity,
      cardOpacity: (json['cardOpacity'] as num?)?.toDouble() ?? defaults.cardOpacity,
      cardLeftN: (json['cardLeftN'] as num?)?.toDouble() ?? defaults.cardLeftN,
      cardTopN: (json['cardTopN'] as num?)?.toDouble() ?? defaults.cardTopN,
      cardWidthN: (json['cardWidthN'] as num?)?.toDouble() ?? defaults.cardWidthN,
      cardHeightN: (json['cardHeightN'] as num?)?.toDouble() ?? defaults.cardHeightN,
      cardBackgroundColorValue: json['cardBackgroundColorValue'] as int? ?? defaults.cardBackgroundColorValue,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? defaults.fontSize,
      textColorValue: json['textColorValue'] as int? ?? defaults.textColorValue,
      effectColorValue: json['effectColorValue'] as int? ?? defaults.effectColorValue,
      fontFamily: json['fontFamily'] as String? ?? defaults.fontFamily,
      textEffectId: json['textEffectId'] as String? ?? defaults.textEffectId,
      barNotificationsEnabled: json['barNotificationsEnabled'] as bool? ?? defaults.barNotificationsEnabled,
      barTiming: json['barTiming'] != null ? _barTimingFromJson(json['barTiming'] as int) : defaults.barTiming,
      barIntervalMinutes: json['barIntervalMinutes'] as int? ?? defaults.barIntervalMinutes,
      barTimeOfDayMinutes: json['barTimeOfDayMinutes'] as int? ?? defaults.barTimeOfDayMinutes,
      popupOnOpenEnabled: json['popupOnOpenEnabled'] as bool? ?? defaults.popupOnOpenEnabled,
      popupTiming: json['popupTiming'] != null ? _popupTimingFromJson(json['popupTiming'] as int) : defaults.popupTiming,
      popupTimeOfDayMinutes: json['popupTimeOfDayMinutes'] as int? ?? defaults.popupTimeOfDayMinutes,
      popupBetweenStartMinutes: json['popupBetweenStartMinutes'] as int? ?? defaults.popupBetweenStartMinutes,
      popupBetweenEndMinutes: json['popupBetweenEndMinutes'] as int? ?? defaults.popupBetweenEndMinutes,
    );
  }
}