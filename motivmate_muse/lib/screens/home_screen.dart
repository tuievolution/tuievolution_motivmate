import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../app_state.dart';
import '../models/theme_presets.dart';
import '../widgets/editing_drawer.dart';
import '../widgets/quote_card.dart';
import '../widgets/settings_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  ColorFilter? _buildColorFilter(String id) {
    switch (id) {
      case 'sepia':
        return const ColorFilter.mode(
          Color(0xFF7A4D2A),
          BlendMode.color,
        );
      case 'mono':
        // Grayscale matrix.
        return ColorFilter.matrix(const <double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case 'vintage':
        return const ColorFilter.mode(
          Color(0xFFB08968),
          BlendMode.softLight,
        );
      case 'cinematic':
        return const ColorFilter.mode(
          Color(0xFF1B1B1B),
          BlendMode.darken,
        );
      case 'none':
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final preset = themePresets
        .firstWhere((e) => e.id == appState.settings.themeId, orElse: () => themePresets.first);
    final screenshotController = ScreenshotController();

    return Scaffold(
      drawer: const SettingsDrawer(),
      body: SafeArea(
        child: Builder(
          builder: (scaffoldContext) => Screenshot(
            controller: screenshotController,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final cardWidth = appState.settings.cardWidthPx.clamp(180.0, 420.0);
                final cardHeight = appState.settings.cardHeightPx.clamp(150.0, 520.0);

                const cardTopInset = 84.0;
                const cardBottomInset = 170.0;
                final leftMaxPx = max(0.0, constraints.maxWidth - cardWidth);
                final topAreaHeight =
                    max(0.0, constraints.maxHeight - cardHeight - cardTopInset - cardBottomInset);

                final effectiveBlur =
                    appState.isOriginalView ? 0.0 : appState.settings.blurSigma;

                final showCard = appState.isQuoteVisible && !appState.isOriginalView;

                final normalizedLeft = appState.settings.cardLeftN.clamp(0.0, 1.0);
                final normalizedTop = appState.settings.cardTopN.clamp(0.0, 1.0);

                final cardLeft = normalizedLeft * leftMaxPx;
                final cardTop = cardTopInset + normalizedTop * topAreaHeight;

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
                    if (colorFilter == null)
                      backgroundImage
                    else
                      ColorFiltered(colorFilter: colorFilter, child: backgroundImage),
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
                        color: preset.overlayColor.withOpacity(
                          appState.isOriginalView ? 0 : appState.settings.backgroundOverlayOpacity,
                        ),
                      ),
                    ),
                  ],
                );

                Future<void> saveCurrentView() async {
                  final bytes = await screenshotController.capture(pixelRatio: 2.0);
                  if (bytes == null) return;
                  await ImageGallerySaver.saveImage(
                    bytes,
                    quality: 100,
                    name: 'motivmate_${DateTime.now().millisecondsSinceEpoch}',
                  );
                  if (!scaffoldContext.mounted) return;
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    const SnackBar(content: Text('Gorsel galeriye kaydedildi.')),
                  );
                }

                return Stack(
                  children: [
                    Positioned.fill(child: blurredBackground),
                    Positioned(
                      top: 8,
                      left: 0,
                      child: IconButton(
                        onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                        icon: const Icon(Icons.menu),
                      ),
                    ),
                    if (showCard)
                      Positioned(
                        left: cardLeft,
                        top: cardTop,
                        child: QuoteCard(
                          width: cardWidth,
                          height: cardHeight,
                          text: appState.quote.text,
                          author: appState.quote.author,
                          cardBackgroundColor: preset.cardBackgroundColor,
                          quoteTextColor:
                              Color(appState.settings.textColorValue),
                          opacity: appState.settings.cardOpacity,
                          fontSize: appState.settings.fontSize,
                          fontFamily: appState.settings.fontFamily,
                          showBackground: appState.settings.showCardBackground,
                        ),
                      ),
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
                            color: Colors.white.withOpacity(0.86),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionButton(
                                icon: Icons.edit,
                                onTap: () async {
                                  showModalBottomSheet<void>(
                                    context: scaffoldContext,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(18),
                                      ),
                                    ),
                                    builder: (_) => EditingDrawer(
                                      appState: appState,
                                      onDownload: saveCurrentView,
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
                                onTap: saveCurrentView,
                              ),
                              const SizedBox(width: 10),
                              _ActionButton(
                                icon: Icons.settings,
                                onTap: () {
                                  Scaffold.of(scaffoldContext).openDrawer();
                                },
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
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: ShapeDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: const CircleBorder(),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black.withOpacity(0.8)),
        onPressed: onTap,
      ),
    );
  }
}

