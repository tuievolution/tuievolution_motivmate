enum PopupTiming {
  immediate,
  timeOfDay,
  betweenHours,
}

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

  // Card edits
  final bool showCard;
  final bool showCardBackground;
  final double backgroundOverlayOpacity; // overlay over background image
  final double cardOpacity; // card container opacity
  final double cardLeftN; // 0..1
  final double cardTopN; // 0..1
  final double cardWidthPx; // px
  final double cardHeightPx; // px

  // Text edits
  final double fontSize;
  final int textColorValue;
  final String fontFamily;

  // Notifications
  final bool barNotificationsEnabled;
  final bool popupOnOpenEnabled;
  final BarTiming barTiming;
  final int barIntervalMinutes; // when barTiming == intervalMinutes
  final int barTimeOfDayMinutes; // minutes after midnight when timeOfDay

  final PopupTiming popupTiming;
  final int popupTimeOfDayMinutes;
  final int popupBetweenStartMinutes;
  final int popupBetweenEndMinutes;

  const AppSettings({
    required this.themeId,
    required this.appLanguage,
    required this.blurSigma,
    required this.photoFilterId,
    required this.showCard,
    required this.showCardBackground,
    required this.backgroundOverlayOpacity,
    required this.cardOpacity,
    required this.cardLeftN,
    required this.cardTopN,
    required this.cardWidthPx,
    required this.cardHeightPx,
    required this.fontSize,
    required this.textColorValue,
    required this.fontFamily,
    required this.barNotificationsEnabled,
    required this.popupOnOpenEnabled,
    required this.barTiming,
    required this.barIntervalMinutes,
    required this.barTimeOfDayMinutes,
    required this.popupTiming,
    required this.popupTimeOfDayMinutes,
    required this.popupBetweenStartMinutes,
    required this.popupBetweenEndMinutes,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      themeId: 'glassmorphism',
      appLanguage: 'tr',
      blurSigma: 10,
      photoFilterId: 'none',
      showCard: true,
      showCardBackground: true,
      backgroundOverlayOpacity: 0.35,
      cardOpacity: 0.92,
      cardLeftN: 0.1,
      cardTopN: 0.22,
      cardWidthPx: 330,
      cardHeightPx: 260,
      fontSize: 28,
      textColorValue: 0xFF2A1B12,
      fontFamily: 'Georgia',
      barNotificationsEnabled: false,
      popupOnOpenEnabled: true,
      barTiming: BarTiming.intervalMinutes,
      barIntervalMinutes: 120,
      barTimeOfDayMinutes: 9 * 60,
      popupTiming: PopupTiming.betweenHours,
      popupTimeOfDayMinutes: 9 * 60,
      popupBetweenStartMinutes: 8 * 60,
      popupBetweenEndMinutes: 22 * 60,
    );
  }

  AppSettings copyWith({
    String? themeId,
    String? appLanguage,
    double? blurSigma,
    String? photoFilterId,
    bool? showCard,
    bool? showCardBackground,
    double? backgroundOverlayOpacity,
    double? cardOpacity,
    double? cardLeftN,
    double? cardTopN,
    double? cardWidthPx,
    double? cardHeightPx,
    double? fontSize,
    int? textColorValue,
    String? fontFamily,
    bool? barNotificationsEnabled,
    bool? popupOnOpenEnabled,
    BarTiming? barTiming,
    int? barIntervalMinutes,
    int? barTimeOfDayMinutes,
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
      showCard: showCard ?? this.showCard,
      showCardBackground: showCardBackground ?? this.showCardBackground,
      backgroundOverlayOpacity:
          backgroundOverlayOpacity ?? this.backgroundOverlayOpacity,
      cardOpacity: cardOpacity ?? this.cardOpacity,
      cardLeftN: cardLeftN ?? this.cardLeftN,
      cardTopN: cardTopN ?? this.cardTopN,
      cardWidthPx: cardWidthPx ?? this.cardWidthPx,
      cardHeightPx: cardHeightPx ?? this.cardHeightPx,
      fontSize: fontSize ?? this.fontSize,
      textColorValue: textColorValue ?? this.textColorValue,
      fontFamily: fontFamily ?? this.fontFamily,
      barNotificationsEnabled:
          barNotificationsEnabled ?? this.barNotificationsEnabled,
      popupOnOpenEnabled: popupOnOpenEnabled ?? this.popupOnOpenEnabled,
      barTiming: barTiming ?? this.barTiming,
      barIntervalMinutes: barIntervalMinutes ?? this.barIntervalMinutes,
      barTimeOfDayMinutes: barTimeOfDayMinutes ?? this.barTimeOfDayMinutes,
      popupTiming: popupTiming ?? this.popupTiming,
      popupTimeOfDayMinutes:
          popupTimeOfDayMinutes ?? this.popupTimeOfDayMinutes,
      popupBetweenStartMinutes:
          popupBetweenStartMinutes ?? this.popupBetweenStartMinutes,
      popupBetweenEndMinutes:
          popupBetweenEndMinutes ?? this.popupBetweenEndMinutes,
    );
  }

  static int _popupTimingToJson(PopupTiming t) => t.index;
  static PopupTiming _popupTimingFromJson(int v) =>
      PopupTiming.values[v];
  static int _barTimingToJson(BarTiming t) => t.index;
  static BarTiming _barTimingFromJson(int v) => BarTiming.values[v];

  Map<String, Object?> toJson() => {
        'themeId': themeId,
        'appLanguage': appLanguage,
        'blurSigma': blurSigma,
        'photoFilterId': photoFilterId,
        'showCard': showCard,
        'showCardBackground': showCardBackground,
        'backgroundOverlayOpacity': backgroundOverlayOpacity,
        'cardOpacity': cardOpacity,
        'cardLeftN': cardLeftN,
        'cardTopN': cardTopN,
        'cardWidthPx': cardWidthPx,
        'cardHeightPx': cardHeightPx,
        'fontSize': fontSize,
        'textColorValue': textColorValue,
        'fontFamily': fontFamily,
        'barNotificationsEnabled': barNotificationsEnabled,
        'popupOnOpenEnabled': popupOnOpenEnabled,
        'barTiming': _barTimingToJson(barTiming),
        'barIntervalMinutes': barIntervalMinutes,
        'barTimeOfDayMinutes': barTimeOfDayMinutes,
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
      photoFilterId:
          json['photoFilterId'] as String? ?? defaults.photoFilterId,
      showCard: json['showCard'] as bool? ?? defaults.showCard,
      showCardBackground:
          json['showCardBackground'] as bool? ?? defaults.showCardBackground,
      backgroundOverlayOpacity: (json['backgroundOverlayOpacity'] as num?)
              ?.toDouble() ??
          defaults.backgroundOverlayOpacity,
      cardOpacity: (json['cardOpacity'] as num?)?.toDouble() ??
          defaults.cardOpacity,
      cardLeftN: (json['cardLeftN'] as num?)?.toDouble() ??
          defaults.cardLeftN,
      cardTopN: (json['cardTopN'] as num?)?.toDouble() ?? defaults.cardTopN,
      cardWidthPx:
          (json['cardWidthPx'] as num?)?.toDouble() ?? defaults.cardWidthPx,
      cardHeightPx:
          (json['cardHeightPx'] as num?)?.toDouble() ?? defaults.cardHeightPx,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? defaults.fontSize,
      textColorValue: json['textColorValue'] as int? ?? defaults.textColorValue,
      fontFamily: json['fontFamily'] as String? ?? defaults.fontFamily,
      barNotificationsEnabled:
          json['barNotificationsEnabled'] as bool? ?? defaults.barNotificationsEnabled,
      popupOnOpenEnabled:
          json['popupOnOpenEnabled'] as bool? ?? defaults.popupOnOpenEnabled,
      barTiming: json['barTiming'] != null
          ? _barTimingFromJson(json['barTiming'] as int)
          : defaults.barTiming,
      barIntervalMinutes:
          json['barIntervalMinutes'] as int? ?? defaults.barIntervalMinutes,
      barTimeOfDayMinutes: json['barTimeOfDayMinutes'] as int? ??
          defaults.barTimeOfDayMinutes,
      popupTiming: json['popupTiming'] != null
          ? _popupTimingFromJson(json['popupTiming'] as int)
          : defaults.popupTiming,
      popupTimeOfDayMinutes: json['popupTimeOfDayMinutes'] as int? ??
          defaults.popupTimeOfDayMinutes,
      popupBetweenStartMinutes:
          json['popupBetweenStartMinutes'] as int? ??
              defaults.popupBetweenStartMinutes,
      popupBetweenEndMinutes:
          json['popupBetweenEndMinutes'] as int? ?? defaults.popupBetweenEndMinutes,
    );
  }
}

