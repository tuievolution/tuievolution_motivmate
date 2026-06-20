import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // EKLENDİ

import '../app_state.dart';
import '../services/storage_service.dart';
import '../services/quote_service.dart';
import '../services/notification_service.dart';
import '../services/billing_service.dart';

class SplashScreen extends StatefulWidget {
  final void Function(AppState appState) onInitializationComplete;

  const SplashScreen({
    super.key,
    required this.onInitializationComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  String _loadingText = "Sistem kontrol ediliyor...";
  bool _hasInternet = true;
  bool _isFirstLaunch = true;
  StreamSubscription? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  bool _isOffline(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.none) || results.isEmpty;
  }

  Future<void> _startLoading() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = !(prefs.getBool('isFirstLaunchCompleted') ?? false);

    var results = await Connectivity().checkConnectivity();
    
    if (_isOffline(results)) {
      setState(() {
        _hasInternet = false;
        if (_isFirstLaunch) {
          _loadingText = "İlk kurulum için internet bağlantısı bekleniyor...";
        } else {
          _loadingText = "Çevrimdışı modda başlatılıyor...";
        }
      });

      // EĞER İLK AÇILIŞSA VE İNTERNET YOKSA: Uygulamayı burada kitle, içeri alma!
      if (_isFirstLaunch) {
        _connectivitySub = Connectivity().onConnectivityChanged.listen((newResults) {
          if (!_isOffline(newResults)) {
            _connectivitySub?.cancel(); // İnternet geldi, dinlemeyi bırak
            setState(() { 
              _hasInternet = true; 
              _loadingText = "Bağlantı sağlandı, devam ediliyor...";
            });
            _proceedWithLoading(); // Yüklemeyi şimdi başlat
          }
        });
        return; // İşlemi burada durdur, internet gelene kadar aşağı geçme.
      }
    }

    // İlk açılış değilse veya ilk açılış olup internet varsa direkt yüklemeye geç
    _proceedWithLoading();
  }

  Future<void> _proceedWithLoading() async {
    setState(() { _progress = 0.2; _loadingText = "Ayarlar yükleniyor..."; });
    final storageService = StorageService();
    final initialSettings = await storageService.loadSettings();
    await Future.delayed(const Duration(milliseconds: 300)); 

    setState(() { _progress = 0.5; _loadingText = "Günün motivasyonu hazırlanıyor..."; });
    final quoteService = QuoteService();
    final initialQuote = await quoteService.getRandomQuote(language: initialSettings.appLanguage);
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() { _progress = 0.7; _loadingText = "Sistem bildirimleri ayarlanıyor..."; });
    final notificationService = NotificationService();
    await notificationService.init();
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() { _progress = 0.9; _loadingText = "Servisler başlatılıyor..."; });
    final billingService = BillingService();
    await billingService.init();
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() { _progress = 1.0; _loadingText = "MotivMood Hazır!"; });
    await Future.delayed(const Duration(milliseconds: 300));

    // Her şey başarıyla yüklendiği için ilk kurulumu tamamlandı olarak işaretle
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunchCompleted', true);

    final appState = AppState(
      storageService: storageService,
      quoteService: quoteService,
      notificationService: notificationService,
      billingService: billingService,
      initialSettings: initialSettings,
      initialQuote: initialQuote,
    );

    widget.onInitializationComplete(appState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/motivmoodlogo.png', 
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.favorite_rounded, size: 80, color: Color(0xFF9B5DE5)),
                ),
              ),
              
              const SizedBox(height: 40),
              
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: _progress),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9B5DE5)),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              Text(
                _loadingText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _hasInternet ? Colors.white70 : Colors.orangeAccent.shade200,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}