import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quote.dart';

class QuoteService {
  static const int _imageCount = 419; // max image number in ImageKit
  static const String _imageKitBaseUrl = 'https://ik.imagekit.io/tuievolution/images';
  
  final _rng = Random();

  // Cached quote list per language
  final Map<String, List<Quote>> _cacheByLanguage = {};

  String _randomImageKitUrl() {
    final imageIndex = _rng.nextInt(_imageCount) + 1;
    // HATA BURADAYDI: "?tr=f-webp" kısmı tamamen silindi
    return '$_imageKitBaseUrl/bg_$imageIndex.jpg';
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
        imageAsset: '', // will be set dynamically
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

  Future<Quote> getRandomQuote({
    required String language,
    bool forceRefresh = false,
  }) async {
    final quotes = await getAllQuotes(language: language);
    if (quotes.isEmpty) {
      return Quote(
        textTr: 'Motivasyon, alışkanlıkların doğal sonucudur.',
        authorTr: 'MotivMood',
        textEn: 'Motivation is the natural result of habits.',
        authorEn: 'MotivMood',
        imageAsset: _randomImageKitUrl(),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    final savedDate = prefs.getString('dailyQuoteDate');
    final savedIndex = prefs.getInt('dailyQuoteIndex');
    final savedImage = prefs.getString('dailyQuoteImage');

    if (!forceRefresh && savedDate == todayStr && savedIndex != null && savedImage != null) {
      // Return today's saved quote and image
      if (savedIndex >= 0 && savedIndex < quotes.length) {
        final q = quotes[savedIndex];
        // Fix any old URLs (motivmood, image_, double slashes) by reconstructing the URL
        String safeSavedImage = savedImage;
        final regex = RegExp(r'(?:bg_|image_)(\d+)\.jpg');
        final match = regex.firstMatch(savedImage);
        if (match != null) {
          final idx = match.group(1);
          // HATA BURADAYDI: "?tr=f-webp" kısmı tamamen silindi
          safeSavedImage = '$_imageKitBaseUrl/bg_$idx.jpg';
        }

        return Quote(
          textTr: q.textTr,
          authorTr: q.authorTr,
          textEn: q.textEn,
          authorEn: q.authorEn,
          imageAsset: safeSavedImage,
        );
      }
    }

    // Otherwise, generate a new quote and image
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

    final imageKitUrl = _randomImageKitUrl();

    // Save for today
    await prefs.setString('dailyQuoteDate', todayStr);
    await prefs.setInt('dailyQuoteIndex', selectedIndex);
    await prefs.setString('dailyQuoteImage', imageKitUrl);

    final q = quotes[selectedIndex];
    return Quote(
      textTr: q.textTr,
      authorTr: q.authorTr,
      textEn: q.textEn,
      authorEn: q.authorEn,
      imageAsset: imageKitUrl,
    );
  }

  void clearCache() {
    _cacheByLanguage.clear();
  }
}