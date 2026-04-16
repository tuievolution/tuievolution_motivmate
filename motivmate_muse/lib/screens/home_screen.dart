import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    return Scaffold(
      drawer: const SettingsDrawer(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            const baseCardWidth = 330.0;
            const baseCardHeight = 260.0;
            final cardWidth = baseCardWidth * appState.settings.cardScale;
            final cardHeight = baseCardHeight * appState.settings.cardScale;

            const cardTopInset = 84.0;
            const cardBottomInset = 170.0;
            final leftMaxPx = max(0.0, constraints.maxWidth - cardWidth);
            final topAreaHeight =
                max(0.0, constraints.maxHeight - cardHeight - cardTopInset - cardBottomInset);

            final effectiveBlur =
                appState.isOriginalView ? 0.0 : appState.settings.blurSigma;

            final showCard = appState.settings.showCard && !appState.isOriginalView;

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

            return Stack(
              children: [
                Positioned.fill(child: blurredBackground),
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          icon: const Icon(Icons.menu),
                        ),
                        const Spacer(),
                        Text(
                          'MotivMate',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black.withOpacity(0.75),
                          ),
                        ),
                        const Spacer(),
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black12,
                          child: Icon(Icons.person_outline, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),

                // Quote card (draggable).
                if (showCard)
                  Positioned(
                    left: cardLeft,
                    top: cardTop,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final denomW = leftMaxPx == 0 ? 1 : leftMaxPx;
                        final denomH = topAreaHeight == 0 ? 1 : topAreaHeight;
                        final nx = (appState.settings.cardLeftN +
                                details.delta.dx / denomW)
                            .clamp(0.0, 1.0);
                        final ny = (appState.settings.cardTopN +
                                details.delta.dy / denomH)
                            .clamp(0.0, 1.0);
                        appState.updateSettingsTemporary(
                          appState.settings.copyWith(
                            cardLeftN: nx,
                            cardTopN: ny,
                          ),
                        );
                      },
                      onPanEnd: (_) async {
                        await appState.persistSettings();
                      },
                      child: Transform.scale(
                        scale: appState.settings.cardScale,
                        child: QuoteCard(
                          width: baseCardWidth,
                          height: baseCardHeight,
                          text: appState.quote.text,
                          author: appState.quote.author,
                          cardBackgroundColor: preset.cardBackgroundColor,
                          quoteTextColor:
                              Color(appState.settings.textColorValue),
                          opacity: appState.settings.cardOpacity,
                          fontSize: appState.settings.fontSize,
                          fontFamily: appState.settings.fontFamily,
                        ),
                      ),
                    ),
                  ),

                // Bottom action buttons.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          icon: Icons.edit,
                          onTap: () async {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(18),
                                ),
                              ),
                              builder: (_) => EditingDrawer(appState: appState),
                            );
                          },
                        ),
                        const SizedBox(width: 18),
                        _ActionButton(
                          icon: appState.isOriginalView
                              ? Icons.favorite
                              : Icons.favorite_border,
                          onTap: () {
                            appState.toggleOriginalView();
                          },
                        ),
                        const SizedBox(width: 18),
                        _ActionButton(
                          icon: Icons.settings,
                          onTap: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ],
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

