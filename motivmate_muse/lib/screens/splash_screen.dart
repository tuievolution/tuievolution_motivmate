import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  String _loadingText = "Bağlantı kontrol ediliyor...";
  bool _hasInternet = true;
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
    // 1. İnternet Kontrolü
    var results = await Connectivity().checkConnectivity();
    
    if (_isOffline(results)) {
      setState(() {
        _hasInternet = false;
        _loadingText = "İnternet bağlantısı bekleniyor...\nLütfen Wi-Fi veya Hücresel Veriyi açın.";
      });
      
      // İnternet gelene kadar bekle ve dinle
      _connectivitySub = Connectivity().onConnectivityChanged.listen((newResults) {
        if (!_isOffline(newResults)) {
          _connectivitySub?.cancel(); // İnternet geldi, dinlemeyi bırak
          setState(() { 
            _hasInternet = true; 
            _loadingText = "Bağlantı sağlandı, devam ediliyor...";
          });
          _proceedWithLoading();
        }
      });
    } else {
      // İnternet varsa direkt yüklemeye geç
      _proceedWithLoading();
    }
  }

  Future<void> _proceedWithLoading() async {
    // Adım 1: Ayarları Yükle
    setState(() { _progress = 0.2; _loadingText = "Kullanıcı ayarları yükleniyor..."; });
    final storageService = StorageService();
    final initialSettings = await storageService.loadSettings();
    await Future.delayed(const Duration(milliseconds: 400)); // Animasyon hissi için minik bekleme

    // Adım 2: Günün Sözü ve Fotoğrafını Hazırla
    setState(() { _progress = 0.5; _loadingText = "Günün motivasyonu hazırlanıyor..."; });
    final quoteService = QuoteService();
    final initialQuote = await quoteService.getRandomQuote(language: initialSettings.appLanguage);
    await Future.delayed(const Duration(milliseconds: 500));

    // Adım 3: Bildirimleri Ayarla
    setState(() { _progress = 0.7; _loadingText = "Sistem bildirimleri ayarlanıyor..."; });
    final notificationService = NotificationService();
    await notificationService.init();
    await Future.delayed(const Duration(milliseconds: 300));

    // Adım 4: Premium ve Ödeme Servisleri
    setState(() { _progress = 0.9; _loadingText = "Servisler başlatılıyor..."; });
    final billingService = BillingService();
    await billingService.init();
    await Future.delayed(const Duration(milliseconds: 300));

    // Adım 5: Bitiş
    setState(() { _progress = 1.0; _loadingText = "MotivMood Hazır!"; });
    await Future.delayed(const Duration(milliseconds: 400));

    // Tüm servisleri AppState içine paketle
    final appState = AppState(
      storageService: storageService,
      quoteService: quoteService,
      notificationService: notificationService,
      billingService: billingService,
      initialSettings: initialSettings,
      initialQuote: initialQuote,
    );

    // Kök widget'a (main.dart) uygulamanın hazır olduğunu haber ver
    widget.onInitializationComplete(appState);
  }

  @override
  Widget build(BuildContext context) {
    // Yükleme ekranı için şık ve karanlık bir tema
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo veya İkon
              if (!_hasInternet)
                const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.redAccent)
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/motivmoodlogo.png', // Logonun yolu doğruysa görünecektir
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.favorite_rounded, size: 80, color: Color(0xFF9B5DE5)),
                  ),
                ),
              
              const SizedBox(height: 40),
              
              // Animasyonlu İlerleme Çubuğu (Progress Bar)
              if (_hasInternet)
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
              
              // Yükleme Metni
              Text(
                _loadingText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _hasInternet ? Colors.white70 : Colors.redAccent.shade200,
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