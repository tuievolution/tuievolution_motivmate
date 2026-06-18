import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quote.dart';

class QuoteService {
  static const int _imageCount = 419; 
  static const String _imageKitBaseUrl = 'https://ik.imagekit.io/tuievolution/images';
  
  final _rng = Random();
  final Map<String, List<Quote>> _cacheByLanguage = {};

  Future<List<Quote>> _loadAllQuotes() async {
    const fieldDelimiter = ',';
    final csvRaw = await rootBundle.loadString(
      'assets/data/master_quotes_turkish.csv',
    );

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
        imageAsset: '', 
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
    
    final now = DateTime.now();
    
    // EVRENSEL MATEMATİK: Belirli bir tarihten itibaren geçen gün sayısı.
    // Bu sayede herkesin telefonunda aynı indeksteki söz ve arka plan görünür.
    final daysSinceEpoch = DateTime(now.year, now.month, now.day)
        .difference(DateTime(2024, 1, 1))
        .inDays;
    
    // Herkes için o günün ortak arka plan fotoğrafını seçiyoruz
    final globalDailyImageIndex = (daysSinceEpoch % _imageCount) + 1;
    final dailyImage = '$_imageKitBaseUrl/bg_$globalDailyImageIndex.jpg?tr=w-1080,f-auto';

    if (quotes.isEmpty) {
      return Quote(
        textTr: 'Motivasyon, alışkanlıkların doğal sonucudur.',
        authorTr: 'MotivMood',
        textEn: 'Motivation is the natural result of habits.',
        authorEn: 'MotivMood',
        imageAsset: dailyImage,
      );
    }

    // Herkes için o günün ortak sözü
    final globalDailyQuoteIndex = daysSinceEpoch % quotes.length;
    final prefs = await SharedPreferences.getInstance();
    
    // Kullanıcının gördüğü sözlerin hafızası (1 yıllık)
    List<String> shownList = prefs.getStringList('shownQuotes') ?? [];

    // DURUM 1: NORMAL AÇILIŞ (Ekstra söz istenmedi, ortak sözü ver)
    if (!forceRefresh) {
      // Günün evrensel sözünü, tekrar karşısına çıkmasın diye kullanıcının hafızasına da ekliyoruz
      if (!shownList.contains(globalDailyQuoteIndex.toString())) {
        shownList.add(globalDailyQuoteIndex.toString());
        
        // Sadece son 365 sözü hafızada tut (Yılda bir sıfırlansın diye)
        if (shownList.length > 365) {
          shownList.removeAt(0); 
        }
        await prefs.setStringList('shownQuotes', shownList);
      }

      final q = quotes[globalDailyQuoteIndex];
      return Quote(
        textTr: q.textTr,
        authorTr: q.authorTr,
        textEn: q.textEn,
        authorEn: q.authorEn,
        imageAsset: dailyImage, 
      );
    }

    // DURUM 2: EKSTRA SÖZ (Kullanıcı reklam izledi / premium)
    List<int> unshownIndices = [];
    for (int i = 0; i < quotes.length; i++) {
      // Hem hafızadaki son 365 sözü hem de günün ortak sözünü atlıyoruz
      if (!shownList.contains(i.toString()) && i != globalDailyQuoteIndex) {
        unshownIndices.add(i);
      }
    }

    // Eğer çok düşük ihtimalle tüm sözler tükenmişse, hafızayı temizle ama günün sözünü yine verme
    if (unshownIndices.isEmpty) {
      shownList.clear();
      unshownIndices = List.generate(quotes.length, (i) => i);
      unshownIndices.remove(globalDailyQuoteIndex);
    }

    // Geri kalanlardan rastgele birini seçiyoruz
    final selectedIndex = unshownIndices[_rng.nextInt(unshownIndices.length)];
    
    // Gösterilen ekstra sözü hemen hafızaya al (365 limitli)
    shownList.add(selectedIndex.toString());
    if (shownList.length > 365) {
      shownList.removeAt(0);
    }
    await prefs.setStringList('shownQuotes', shownList);

    final q = quotes[selectedIndex];
    return Quote(
      textTr: q.textTr,
      authorTr: q.authorTr,
      textEn: q.textEn,
      authorEn: q.authorEn,
      imageAsset: dailyImage, // Arka plan fotoğrafı KESİNLİKLE günün fotoğrafı kalıyor
    );
  }

  void clearCache() {
    _cacheByLanguage.clear();
  }
}