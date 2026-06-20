import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as ads;
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'app_state.dart';
import 'models/theme_presets.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart'; // YENİ EKLENEN YÜKLEME EKRANI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ads.MobileAds.instance.initialize();
  
  runApp(const MotivMoodRoot());
}

// Uygulamanın Kök Widget'ı (Durum Yöneticisi)
class MotivMoodRoot extends StatefulWidget {
  const MotivMoodRoot({super.key});

  @override
  State<MotivMoodRoot> createState() => _MotivMoodRootState();
}

class _MotivMoodRootState extends State<MotivMoodRoot> {
  AppState? _appState; // Başlangıçta boş. SplashScreen bunu dolduracak.

  @override
  Widget build(BuildContext context) {
    // 1. AŞAMA: Uygulama henüz yüklenmediyse Yükleme Ekranını (Splash) göster.
    if (_appState == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MotivMood Yükleniyor',
        home: SplashScreen(
          onInitializationComplete: (initializedState) {
            // Yükleme %100 olunca bu fonksiyon çalışır ve asıl uygulamaya geçer.
            setState(() {
              _appState = initializedState;
            });
          },
        ),
      );
    }

    // 2. AŞAMA: Yükleme bitti, Provider'ı bağla ve asıl uygulamayı çalıştır.
    return ChangeNotifierProvider.value(
      value: _appState!,
      child: const MotivMoodMainApp(),
    );
  }
}

// Asıl Uygulama Çerçevesi (Tema ve Kullanıcı Ekranları)
class MotivMoodMainApp extends StatefulWidget {
  const MotivMoodMainApp({super.key});

  @override
  State<MotivMoodMainApp> createState() => _MotivMoodMainAppState();
}

class _MotivMoodMainAppState extends State<MotivMoodMainApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!mounted) return;
    final appState = context.read<AppState>();
    unawaited(appState.handleAppResumed(context));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final preset = themePresets.firstWhere((e) => e.id == appState.settings.themeId);

    return MaterialApp(
      title: 'MotivMood',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: preset.accentColor),
        useMaterial3: true,
        scaffoldBackgroundColor: preset.backgroundScaffoldColor,
      ),
      // UYGULAMA İÇİNDEYKEN İNTERNET GİDERSE KORUMA EKRANI ÇIKART
      home: StreamBuilder<List<ConnectivityResult>>(
        stream: Connectivity().onConnectivityChanged,
        builder: (context, snapshot) {
          final results = snapshot.data ?? [ConnectivityResult.none];
          final isOffline = results.contains(ConnectivityResult.none) || results.isEmpty;

          if (isOffline) {
            return Scaffold(
              backgroundColor: preset.backgroundScaffoldColor,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded, 
                      size: 80, 
                      color: preset.accentColor.withValues(alpha: 0.5)
                    ),
                    const SizedBox(height: 20),
                    Text(
                      appState.settings.appLanguage == 'en' ? 'No Internet Connection' : 'İnternet Bağlantısı Yok',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: preset.overlayColor),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        appState.settings.appLanguage == 'en' 
                          ? 'Please connect to the internet to see your daily motivation.' 
                          : 'Günlük motivasyonunuzu görmek için lütfen internete bağlanın.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: preset.overlayColor.withValues(alpha: 0.7)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // İnternet var, ana ekranı göster!
          return const HomeScreen();
        },
      ),
    );
  }
}