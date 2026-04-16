import 'dart:convert';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import '../models/quote.dart';

class QuoteService {
  final Map<String, List<Quote>> _cacheByLanguage = {};
  final _rng = Random();
  List<String> _imagePaths = [];

  Future<void> _loadImages() async {
    if (_imagePaths.isNotEmpty) return;
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestJson);
      _imagePaths = manifestMap.keys
          .where((String key) => key.startsWith('assets/images/'))
          .toList();
    } catch (_) {}
  }

  Future<List<Quote>> _loadAllQuotes(String language) async {
    final csvRaw = await rootBundle.loadString('assets/data/master_quotes_turkish.csv');
    final rows = const CsvDecoder(
      fieldDelimiter: ',',
      quoteCharacter: '"',
      skipEmptyLines: true,
    ).convert(csvRaw);
    if (rows.isEmpty) return const [];

    final quotes = <Quote>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 3) continue;
      final textTr = (row[0] ?? '').toString().trim();
      final textEn = (row[1] ?? '').toString().trim();
      final author = (row[2] ?? '').toString().trim();
      
      if (textTr.isEmpty) continue;
      quotes.add(Quote(
        textTr: textTr,
        authorTr: author.isEmpty ? 'Anonim' : author,
        textEn: textEn,
        authorEn: author.isEmpty ? 'Unknown' : author,
        imageAsset: '', // Set dynamically
      ));
    }
    return quotes;
  }

  Future<List<Quote>> getAllQuotes({required String language}) async {
    _cacheByLanguage[language] ??= await _loadAllQuotes(language);
    return _cacheByLanguage[language]!;
  }

  Future<Quote> getRandomQuote({required String language}) async {
    final quotes = await getAllQuotes(language: language);
    await _loadImages();

    final imageAsset = _imagePaths.isNotEmpty
        ? _imagePaths[_rng.nextInt(_imagePaths.length)]
        : 'assets/images/image_1.jpg'; // Fallback

    if (quotes.isEmpty) {
      return Quote(
        textTr: 'Motivasyon, alışkanlıkların doğal sonucudur.',
        authorTr: 'MotivMood',
        textEn: 'Motivation is the natural result of habits.',
        authorEn: 'MotivMood',
        imageAsset: imageAsset,
      );
    }
    
    final q = quotes[_rng.nextInt(quotes.length)];
    return Quote(
      textTr: q.textTr,
      authorTr: q.authorTr,
      textEn: q.textEn,
      authorEn: q.authorEn,
      imageAsset: imageAsset,
    );
  }

  void clearCache() {
    _cacheByLanguage.clear();
  }
}

