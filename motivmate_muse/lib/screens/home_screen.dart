import 'dart:async'; // Zamanlayıcı için eklendi
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
import 'package:cached_network_image/cached_network_image.dart';
import '../cache_limit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      case 'rosy':
        return const ColorFilter.mode(Color(0xFFE91E63), BlendMode.softLight);
      case 'none':
      default:
        return null;
    }
  }

  // ── YENİ: Üstten Kayan Özel Bildirim Barı (Overlay) ──
  void _showTopWarning(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.6), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.repeat_rounded, color: Colors.orangeAccent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Timer(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future<void> _changeImageAd(BuildContext scaffoldCtx, AppState appState) async {
    final canGetNewQuote = await appState.canWatchAd(); 
    if (!scaffoldCtx.mounted) return;

    if (canGetNewQuote) {
      if (appState.billingService.isPremium) {
        await appState.incrementAdWatchAndRefreshQuote();
        if (mounted) setState(() {});
      } else {
        ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
          const SnackBar(content: Text('Reklam yükleniyor...'), duration: Duration(seconds: 1)),
        );

        ads.RewardedAd.load(
          adUnitId: 'ca-app-pub-3940256099942544/5224354917',
          request: const ads.AdRequest(),
          rewardedAdLoadCallback: ads.RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              bool isRewardEarned = false;

              ad.fullScreenContentCallback = ads.FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) async {
                  ad.dispose();
                  if (isRewardEarned) {
                    await appState.incrementAdWatchAndRefreshQuote();
                    if (mounted) setState(() {}); 
                  }
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                },
              );

              ad.show(onUserEarnedReward: (ad, reward) {
                isRewardEarned = true;
              });
            },
            onAdFailedToLoad: (error) {
              if (!scaffoldCtx.mounted) return;
              ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
                const SnackBar(content: Text('Reklam bağlantı hatası. İnternetinizi kontrol edin.')),
              );
            },
          ),
        );
      }
    } else {
      // Limit Doldu: Reklamsız hafızadaki sözler arası geçiş yap
      appState.cycleSeenQuotes();
      if (mounted) setState(() {});
      
      // GÜNCELLEME: SnackBar yerine üstten açılan fonksiyon çağrıldı
      _showTopWarning(
        scaffoldCtx,
        appState.settings.appLanguage == 'en' 
            ? 'Daily limit reached. Cycling today\'s quotes.' 
            : 'Günlük limit doldu. Bugün gelen alıntılar arasında dönülüyor.'
      );
    }
  }

  Future<void> _saveCurrentView(BuildContext scaffoldCtx, AppState appState, ThemePreset preset) async {
    final bool isPremium = appState.billingService.isPremium;

    Future<void> executeCapture() async {
      bool wasVisible = appState.isQuoteVisible;
      if (!wasVisible) {
        appState.setQuoteVisibility(true);
        await Future.delayed(const Duration(milliseconds: 150));
      }
      if (!scaffoldCtx.mounted) return;
      await _captureAndSave(scaffoldCtx, appState, preset);
      if (!wasVisible) {
        appState.setQuoteVisibility(false);
      }
    }

    if (isPremium) {
      await executeCapture();
    } else {
      ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
        const SnackBar(content: Text('İndirme için reklam yükleniyor...'), duration: Duration(seconds: 1)),
      );
      
      ads.RewardedAd.load(
        adUnitId: 'ca-app-pub-3940256099942544/5224354917',
        request: const ads.AdRequest(),
        rewardedAdLoadCallback: ads.RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            bool isRewardEarned = false;

            ad.fullScreenContentCallback = ads.FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (isRewardEarned) executeCapture();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                executeCapture(); 
              },
            );

            ad.show(onUserEarnedReward: (ad, reward) {
              isRewardEarned = true;
            });
          },
          onAdFailedToLoad: (error) {
            executeCapture(); 
          },
        ),
      );
    }
  }

  Future<void> _captureAndSave(BuildContext scaffoldCtx, AppState appState, ThemePreset preset) async {
    try {
      final bytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      if (bytes == null) {
        throw Exception("Görüntü oluşturulamadı.");
      }

      final hasAccess = await Gal.requestAccess(toAlbum: true);
      if (!scaffoldCtx.mounted) return;

      if (hasAccess) {
        await Gal.putImageBytes(bytes, album: 'MotivMood');
        if (!scaffoldCtx.mounted) return;
        ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
          const SnackBar(content: Text('✓ Görsel galeriye kaydedildi.')),
        );
      } else {
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
      body: Builder(
        builder: (scaffoldContext) => LayoutBuilder(
          builder: (ctx, constraints) {
              final effectiveBlur = appState.isOriginalView ? 0.0 : appState.settings.blurSigma;
              final showCard = !appState.isOriginalView && appState.isQuoteVisible;
              final showCardBg = appState.settings.showCardBackground;

              final backgroundImage = CachedNetworkImage(
                imageUrl: appState.quote.imagePath,
                cacheManager: customCacheManager,
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
                            top: MediaQuery.of(context).padding.top + 20,
                            left: 0,
                            right: 0,
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () => appState.toggleOriginalView(),
                                  child: Text(
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
                              top:  appState.settings.cardTopN.clamp(0.0, 1.0) * constraints.maxHeight,
                              width:  appState.settings.cardWidthN.clamp(0.01, 1.0) * constraints.maxWidth,
                              child: QuoteCard(
                                text: appState.quote.text(appState.settings.appLanguage),
                                author: appState.quote.author(appState.settings.appLanguage),
                                cardBackgroundColor: Color(appState.settings.cardBackgroundColorValue),
                                quoteTextColor: Color(appState.settings.textColorValue),
                                effectColor: Color(appState.settings.effectColorValue),
                                opacity: appState.settings.cardOpacity,
                                fontSize: appState.settings.fontSize,
                                fontFamily: appState.settings.fontFamily,
                                textEffectId: appState.settings.textEffectId,
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
                    bottom: MediaQuery.of(context).padding.bottom + 24,
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
                                  builder: (_) => SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.85,
                                    child: EditingDrawer(
                                      appState: appState,
                                      onDownload: () => _saveCurrentView(scaffoldContext, appState, preset),
                                    ),
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
                            // GÜNCELLEME: Limit dolunca ikon otomatik olarak tekrar eden simgeye dönüyor!
                            _ActionButton(
                              icon: appState.isLimitReached ? Icons.repeat_rounded : Icons.shuffle,
                              onTap: () => _changeImageAd(scaffoldContext, appState),
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