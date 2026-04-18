import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as ads;
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../app_state.dart';
import '../models/theme_presets.dart';
import '../widgets/editing_drawer.dart';
import '../widgets/quote_card.dart';
import '../widgets/settings_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controller must live as long as the widget — NOT created in build()
  final ScreenshotController _screenshotController = ScreenshotController();

  ColorFilter? _buildColorFilter(String id) {
    switch (id) {
      case 'sepia':
        return const ColorFilter.mode(Color(0xFF7A4D2A), BlendMode.color);
      case 'mono':
        return ColorFilter.matrix(const <double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'vintage':
        return const ColorFilter.mode(Color(0xFFB08968), BlendMode.softLight);
      case 'warm':
        return const ColorFilter.mode(Color(0xFFFF9800), BlendMode.softLight);
      case 'cool':
        return const ColorFilter.mode(Color(0xFF4264FB), BlendMode.softLight);
      case 'cinematic':
        return const ColorFilter.mode(Color(0xFF1B1B1B), BlendMode.darken);
      case 'rosy':
        return const ColorFilter.mode(Color(0xFFE91E63), BlendMode.softLight);
      case 'faded':
        return const ColorFilter.mode(Color(0xFFCCCCCC), BlendMode.lighten);
      case 'none':
      default:
        return null;
    }
  }

  Future<void> _saveCurrentView(BuildContext scaffoldCtx, AppState appState, ThemePreset preset) async {
    ads.RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Test Ad Unit ID
      request: const ads.AdRequest(),
      rewardedAdLoadCallback: ads.RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(onUserEarnedReward: (ad, reward) {
            _captureAndSave(scaffoldCtx, appState, preset);
          });
        },
        onAdFailedToLoad: (error) {
          _captureAndSave(scaffoldCtx, appState, preset);
        },
      ),
    );
  }

  Future<void> _captureAndSave(BuildContext scaffoldCtx, AppState appState, ThemePreset preset) async {
    try {
      // Build a dedicated widget tree for the output image to ensure consistency
      final exportWidget = SizedBox(
        width: 1080,
        height: 1920,
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    appState.quote.imagePath,
                    fit: BoxFit.cover,
                  ),
                  if (!appState.isOriginalView) ...[
                    // Filter
                    if (appState.settings.photoFilterId != 'none')
                      Opacity(
                        opacity: appState.settings.photoFilterIntensity,
                        child: ColorFiltered(
                          colorFilter: _buildColorFilter(appState.settings.photoFilterId)!,
                          child: Image.asset(
                            appState.quote.imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    // Blur
                    if (appState.settings.blurSigma > 0)
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: appState.settings.blurSigma,
                            sigmaY: appState.settings.blurSigma,
                          ),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    // Overlay
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(
                          alpha: appState.settings.backgroundOverlayOpacity,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Header
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Text(
                'MotivMood',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            // Quote Card
            if (appState.isQuoteVisible)
              Positioned(
                left:   appState.settings.cardLeftN.clamp(0.0, 1.0)   * 1080,
                top:    appState.settings.cardTopN.clamp(0.0, 1.0)    * 1920,
                width:  appState.settings.cardWidthN.clamp(0.01, 1.0) * 1080,
                height: appState.settings.cardHeightN.clamp(0.01, 1.0)* 1920,
                child: QuoteCard(
                  text: appState.quote.text(appState.settings.appLanguage),
                  author: appState.quote.author(appState.settings.appLanguage),
                  cardBackgroundColor: Color(appState.settings.cardBackgroundColorValue),
                  quoteTextColor: Color(appState.settings.textColorValue),
                  opacity: appState.settings.cardOpacity,
                  fontSize: appState.settings.fontSize * 1.5, // Scale for high res
                  fontFamily: appState.settings.fontFamily,
                  showBackground: appState.settings.showCardBackground,
                  fillContainer: true,
                ),
              ),
          ],
        ),
      );

      final bytes = await _screenshotController.captureFromWidget(
        exportWidget,
        pixelRatio: 1.0,
        delay: const Duration(milliseconds: 100),
      );

      final hasAccess = await Gal.requestAccess(toAlbum: true);
      if (hasAccess) {
        await Gal.putImageBytes(bytes, album: 'MotivMood');
        if (!scaffoldCtx.mounted) return;
        ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
          const SnackBar(content: Text('✓ Görsel galeriye kaydedildi.')),
        );
      } else {
        if (!scaffoldCtx.mounted) return;
        ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
          const SnackBar(content: Text('Galeri erişimi reddedildi.')),
        );
      }
    } catch (e) {
      if (!scaffoldCtx.mounted) return;
      ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
        SnackBar(content: Text('Kaydedilemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final preset = themePresets.firstWhere(
      (e) => e.id == appState.settings.themeId,
      orElse: () => themePresets.first,
    );

    return Scaffold(
      drawer: const SettingsDrawer(),
      body: SafeArea(
        child: Builder(
          builder: (scaffoldContext) => LayoutBuilder(
            builder: (ctx, constraints) {
                final effectiveBlur = appState.isOriginalView ? 0.0 : appState.settings.blurSigma;
                final showCard = !appState.isOriginalView && appState.isQuoteVisible;
                final showCardBg = appState.settings.showCardBackground;

                final backgroundImage = Image.asset(
                  appState.quote.imagePath,
                  fit: BoxFit.cover,
                );

                final colorFilter = appState.isOriginalView
                    ? null
                    : _buildColorFilter(appState.settings.photoFilterId);

                final blurredBackground = Stack(
                  fit: StackFit.expand,
                  children: [
                    backgroundImage,
                    if (colorFilter != null)
                      Opacity(
                        opacity: appState.settings.photoFilterIntensity,
                        child: ColorFiltered(colorFilter: colorFilter, child: backgroundImage),
                      ),
                    if (effectiveBlur > 0)
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: effectiveBlur,
                            sigmaY: effectiveBlur,
                          ),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    Positioned.fill(
                      child: Container(
                color: Colors.black.withValues(
                          alpha: appState.isOriginalView
                              ? 0
                              : appState.settings.backgroundOverlayOpacity,
                        ),
                      ),
                    ),
                  ],
                );

                return Stack(
                  children: [
                    Positioned.fill(
                      child: Screenshot(
                        controller: _screenshotController,
                        child: Stack(
                          children: [
                            Positioned.fill(child: blurredBackground),

                            // ── MotivMood Header ──────────────────────────────────
                            Positioned(
                              top: 20,
                              left: 0,
                              right: 0,
                              child: Column(
                                children: [
                                  Text(
                                    'MotivMood',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 3.0,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          blurRadius: 16,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    height: 2,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Quote Card ────────────────────────────────────────
                            if (showCard)
                              Positioned(
                                left: appState.settings.cardLeftN.clamp(0.0, 1.0) * constraints.maxWidth,
                                top:  appState.settings.cardTopN.clamp(0.0, 1.0)  * constraints.maxHeight,
                                width:  appState.settings.cardWidthN.clamp(0.01, 1.0) * constraints.maxWidth,
                                height: appState.settings.cardHeightN.clamp(0.01, 1.0) * constraints.maxHeight,
                                child: QuoteCard(
                                  text: appState.quote.text(appState.settings.appLanguage),
                                  author: appState.quote.author(appState.settings.appLanguage),
                                  cardBackgroundColor: Color(appState.settings.cardBackgroundColorValue),
                                  quoteTextColor: Color(appState.settings.textColorValue),
                                  opacity: appState.settings.cardOpacity,
                                  fontSize: appState.settings.fontSize,
                                  fontFamily: appState.settings.fontFamily,
                                  showBackground: showCardBg,
                                  fillContainer: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ── Bottom Action Bar ─────────────────────────────────
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 24,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionButton(
                                icon: Icons.edit,
                                onTap: () {
                                  showModalBottomSheet<void>(
                                    context: scaffoldContext,
                                    isScrollControlled: true,
                                    backgroundColor: preset.backgroundScaffoldColor,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(18),
                                      ),
                                    ),
                                    builder: (_) => EditingDrawer(
                                      appState: appState,
                                      onDownload: () => _saveCurrentView(scaffoldContext, appState, preset),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              _ActionButton(
                                icon: appState.isQuoteVisible
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                onTap: appState.toggleQuoteVisibility,
                              ),
                              const SizedBox(width: 10),
                              _ActionButton(
                                icon: Icons.download,
                                accentColor: preset.accentColor,
                                onTap: () => _saveCurrentView(scaffoldContext, appState, preset),
                              ),
                              const SizedBox(width: 10),
                              _ActionButton(
                                icon: Icons.settings,
                                onTap: () => Scaffold.of(scaffoldContext).openDrawer(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
            },
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? accentColor;

  const _ActionButton({required this.icon, required this.onTap, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = accentColor ?? cs.primary;
    return Ink(
      decoration: ShapeDecoration(
        color: cs.surfaceContainer.withValues(alpha: 0.9),
        shape: const CircleBorder(),
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onTap,
      ),
    );
  }
}
