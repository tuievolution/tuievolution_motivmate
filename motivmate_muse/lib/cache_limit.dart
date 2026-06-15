import 'package:flutter_cache_manager/flutter_cache_manager.dart';

final customCacheManager = CacheManager(
  Config(
    'motivmood_cache',
    stalePeriod: const Duration(days: 3), // 3 gün boyunca açılmayan resmi sil
    maxNrOfCacheObjects: 40, // Hafızada maksimum 40 resim barındır (~2 MB yer kaplar)
  ),
);