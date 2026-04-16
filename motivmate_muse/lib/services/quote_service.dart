import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import '../models/quote.dart';

class QuoteService {
  final Map<String, List<Quote>> _cacheByLanguage = {};
  final _rng = Random();

  Future<List<Quote>> _loadAllQuotes(String language) async {
    final csvRaw = await rootBundle.loadString('assets/data/quotes.csv');
    final rows = const CsvDecoder(
      fieldDelimiter: ',',
      quoteCharacter: '"',
      skipEmptyLines: true,
    ).convert(csvRaw);
    if (rows.isEmpty) return const [];

    final useEnglish = language.toLowerCase() == 'en';
    final quotes = <Quote>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 5) continue;
      final text = (useEnglish ? row[2] ?? '' : row[0] ?? '').toString().trim();
      final author = (useEnglish ? row[3] ?? '' : row[1] ?? '').toString().trim();
      final imageAsset = (row[4] ?? '').toString().trim();
      if (text.isEmpty) continue;
      quotes.add(Quote(text: text, author: author, imageAsset: imageAsset));
    }
    return quotes;
  }

  Future<List<Quote>> getAllQuotes({required String language}) async {
    _cacheByLanguage[language] ??= await _loadAllQuotes(language);
    return _cacheByLanguage[language]!;
  }

  Future<Quote> getRandomQuote({required String language}) async {
    final quotes = await getAllQuotes(language: language);
    if (quotes.isEmpty) {
      return const Quote(
        text: 'Motivasyon, alışkanlıkların doğal sonucudur.',
        author: 'MotivMate',
        imageAsset: 'placeholder.png',
      );
    }
    return quotes[_rng.nextInt(quotes.length)];
  }

  void clearCache() {
    _cacheByLanguage.clear();
  }
}

