import 'package:flutter/material.dart';

class ThemePreset {
  final String id;
  final String name;
  final Color accentColor;
  final Color backgroundScaffoldColor;
  final Color overlayColor;
  final Color cardBackgroundColor;
  final Color defaultQuoteTextColor;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.accentColor,
    required this.backgroundScaffoldColor,
    required this.overlayColor,
    required this.cardBackgroundColor,
    required this.defaultQuoteTextColor,
  });
}

const List<ThemePreset> themePresets = [
  ThemePreset(
    id: 'glassmorphism',
    name: 'Glassmorphism',
    accentColor: Color(0xFFB89B7E),
    backgroundScaffoldColor: Color(0xFFF4EFE5),
    overlayColor: Color(0xFF2D1E12),
    cardBackgroundColor: Color(0xFFFFFFFB),
    defaultQuoteTextColor: Color(0xFF2A1B12),
  ),
  ThemePreset(
    id: 'dark_emerald',
    name: 'Dark Emerald',
    accentColor: Color(0xFF1B7F66),
    backgroundScaffoldColor: Color(0xFFEFF7F3),
    overlayColor: Color(0xFF07251E),
    cardBackgroundColor: Color(0xFFF7FFFD),
    defaultQuoteTextColor: Color(0xFF071B16),
  ),
  ThemePreset(
    id: 'sunset_gold',
    name: 'Sunset Gold',
    accentColor: Color(0xFFFFA000),
    backgroundScaffoldColor: Color(0xFFFFF2E2),
    overlayColor: Color(0xFF2B1600),
    cardBackgroundColor: Color(0xFFFFFAF1),
    defaultQuoteTextColor: Color(0xFF2B1600),
  ),
  ThemePreset(
    id: 'ocean_dream',
    name: 'Ocean Dream',
    accentColor: Color(0xFF2D8CFF),
    backgroundScaffoldColor: Color(0xFFF0F6FF),
    overlayColor: Color(0xFF071A2B),
    cardBackgroundColor: Color(0xFFFFFBFF),
    defaultQuoteTextColor: Color(0xFF071A2B),
  ),
];

