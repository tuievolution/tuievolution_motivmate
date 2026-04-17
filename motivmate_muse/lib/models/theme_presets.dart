import 'package:flutter/material.dart';

class ThemePreset {
  final String id;
  final String name;
  final Color accentColor;
  final Color backgroundScaffoldColor;
  final Color overlayColor;
  final Color defaultQuoteTextColor;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.accentColor,
    required this.backgroundScaffoldColor,
    required this.overlayColor,
    required this.defaultQuoteTextColor,
  });
}

const List<ThemePreset> themePresets = [
  ThemePreset(
    id: 'amethyst',
    name: 'Amethyst',
    accentColor: Color(0xFF9B5DE5),
    backgroundScaffoldColor: Color(0xFFF9F5FF),
    overlayColor: Color(0xFF2E1A47),
    defaultQuoteTextColor: Color(0xFF1E0A3C),
  ),
  ThemePreset(
    id: 'citrine',
    name: 'Citrine',
    accentColor: Color(0xFFF15BB5),
    backgroundScaffoldColor: Color(0xFFFFF0F5),
    overlayColor: Color(0xFF4A1A2C),
    defaultQuoteTextColor: Color(0xFF2A0A1A),
  ),
  ThemePreset(
    id: 'dark_emerald',
    name: 'Dark Emerald',
    accentColor: Color(0xFF1B7F66),
    backgroundScaffoldColor: Color(0xFFEFF7F3),
    overlayColor: Color(0xFF07251E),
    defaultQuoteTextColor: Color(0xFF071B16),
  ),
  ThemePreset(
    id: 'sunset_gold',
    name: 'Sunset Gold',
    accentColor: Color(0xFFFFA000),
    backgroundScaffoldColor: Color(0xFFFFF2E2),
    overlayColor: Color(0xFF2B1600),
    defaultQuoteTextColor: Color(0xFF2B1600),
  ),
  ThemePreset(
    id: 'ocean_dream',
    name: 'Ocean Dream',
    accentColor: Color(0xFF2D8CFF),
    backgroundScaffoldColor: Color(0xFFF0F6FF),
    overlayColor: Color(0xFF071A2B),
    defaultQuoteTextColor: Color(0xFF071A2B),
  ),
];

