import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quote.dart';

class QuoteService {
  static const int _imageCount = 419; // max image number in assets/images/
  // Known existing image numbers (some are missing e.g. 55, 135, 195...)
  // Build the list dynamically from AssetManifest or use the range
  final _rng = Random();
  List<String> _imagePaths = [];

  // Cached quote list per language
  final Map<String, List<Quote>> _cacheByLanguage = {};

  Future<void> _loadImages() async {
    if (_imagePaths.isNotEmpty) return;
    try {
      // Try AssetManifest.json (Flutter < 3.12)
      final manifestStr = await rootBundle.loadString('AssetManifest.json');
      // The manifest is a JSON map: { "assets/images/image_1.jpg": [...], ... }
      // Simple regex extraction to avoid dart:convert dependency issues
      final regex = RegExp(r'"(assets/images/[^"]+\.jpg)"');
      final matches = regex.allMatches(manifestStr);
      _imagePaths = matches.map((m) => m.group(1)!).toList();
    } catch (_) {
      _imagePaths = [];
    }

    // Fallback: generate paths for image_1 through image_419
    if (_imagePaths.isEmpty) {
      _imagePaths = List.generate(
        _imageCount,
        (i) => 'assets/images/image_${i + 1}.jpg',
      );
    }
  }

  String _randomImagePath() {
    if (_imagePaths.isEmpty) return 'assets/images/image_1.jpg';
    return _imagePaths[_rng.nextInt(_imagePaths.length)];
  }

  Future<List<Quote>> _loadAllQuotes() async {
    const fieldDelimiter = ',';
    final csvRaw = await rootBundle.loadString(
      'assets/data/master_quotes_turkish.csv',
    );

    // Simple CSV parser that handles quoted fields with commas inside
    final lines = csvRaw.split('\n');
    final quotes = <Quote>[];

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final fields = _parseCsvLine(line, fieldDelimiter);
      if (fields.length < 2) continue;

      final textTr = fields[0].trim();
      if (textTr.isEmpty) continue;

      final textEn = fields.length > 1 ? fields[1].trim() : '';
      final author = fields.length > 2 ? fields[2].trim() : '';

      quotes.add(Quote(
        textTr: textTr,
        authorTr: author.isEmpty ? 'Anonim' : author,
        textEn: textEn.isEmpty ? textTr : textEn,
        authorEn: author.isEmpty ? 'Unknown' : author,
        imageAsset: '', // set dynamically per call
      ));
    }
    return quotes;
  }

  List<String> _parseCsvLine(String line, String delimiter) {
    final fields = <String>[];
    final sb = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == delimiter && !inQuotes) {
        fields.add(sb.toString());
        sb.clear();
      } else {
        sb.write(ch);
      }
    }
    fields.add(sb.toString());
    return fields;
  }

  Future<List<Quote>> getAllQuotes({required String language}) async {
    _cacheByLanguage[language] ??= await _loadAllQuotes();
    return _cacheByLanguage[language]!;
  }

  Future<Quote> getRandomQuote({required String language}) async {
    final quotes = await getAllQuotes(language: language);
    await _loadImages();
    final image = _randomImagePath();

    if (quotes.isEmpty) {
      return Quote(
        textTr: 'Motivasyon, alışkanlıkların doğal sonucudur.',
        authorTr: 'MotivMood',
        textEn: 'Motivation is the natural result of habits.',
        authorEn: 'MotivMood',
        imageAsset: image,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> shownList = prefs.getStringList('shownQuotes') ?? [];
    
    List<int> unshownIndices = [];
    for (int i = 0; i < quotes.length; i++) {
      if (!shownList.contains(i.toString())) {
        unshownIndices.add(i);
      }
    }

    if (unshownIndices.isEmpty) {
      shownList.clear();
      unshownIndices = List.generate(quotes.length, (i) => i);
    }

    final selectedIndex = unshownIndices[_rng.nextInt(unshownIndices.length)];
    shownList.add(selectedIndex.toString());
    await prefs.setStringList('shownQuotes', shownList);

    final q = quotes[selectedIndex];
    return Quote(
      textTr: q.textTr,
      authorTr: q.authorTr,
      textEn: q.textEn,
      authorEn: q.authorEn,
      imageAsset: image,
    );
  }

  void clearCache() {
    _cacheByLanguage.clear();
  }
}
