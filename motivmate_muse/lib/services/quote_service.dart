import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import '../models/quote.dart';

class QuoteService {
  List<Quote>? _cache;
  final _rng = Random();

  Future<List<Quote>> _loadAllQuotes() async {
    final csvRaw = await rootBundle.loadString('assets/data/quotes.csv');
    final rows = const CsvDecoder(
      fieldDelimiter: ',',
      quoteCharacter: '"',
      skipEmptyLines: true,
    ).convert(csvRaw);
    if (rows.isEmpty) return const [];

    // Expected header: quote,author,image
    final quotes = <Quote>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 3) continue;
      final text = (row[0] ?? '').toString().trim();
      final author = (row[1] ?? '').toString().trim();
      final imageAsset = (row[2] ?? '').toString().trim();
      if (text.isEmpty) continue;
      quotes.add(Quote(text: text, author: author, imageAsset: imageAsset));
    }
    return quotes;
  }

  Future<List<Quote>> getAllQuotes() async {
    _cache ??= await _loadAllQuotes();
    return _cache!;
  }

  Future<Quote> getRandomQuote() async {
    final quotes = await getAllQuotes();
    if (quotes.isEmpty) {
      return const Quote(
        text: 'Motivasyon, alışkanlıkların doğal sonucudur.',
        author: 'MotivMate',
        imageAsset: 'placeholder.png',
      );
    }
    return quotes[_rng.nextInt(quotes.length)];
  }
}

