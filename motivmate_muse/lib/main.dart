import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as ads;
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'app_state.dart';
import 'models/theme_presets.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/quote_service.dart';
import 'services/storage_service.dart';
import 'services/billing_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ads.MobileAds.instance.initialize();

  final storageService = StorageService();
  final initialSettings = await storageService.loadSettings();

  final quoteService = QuoteService();
  final initialQuote = await quoteService.getRandomQuote(
    language: initialSettings.appLanguage,
  );

  final notificationService = NotificationService();
  await notificationService.init();

  final billingService = BillingService();
  await billingService.init();

  final appState = AppState(
    storageService: storageService,
    quoteService: quoteService,
    notificationService: notificationService,
    billingService: billingService,
    initialSettings: initialSettings,
    initialQuote: initialQuote,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => appState,
      child: const MotivMoodRoot(),
    ),
  );
}

class MotivMoodRoot extends StatefulWidget {
  const MotivMoodRoot({super.key});

  @override
  State<MotivMoodRoot> createState() => _MotivMoodRootState();
}

class _MotivMoodRootState extends State<MotivMoodRoot>
    with WidgetsBindingObserver {
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

          return const HomeScreen();
        },
      ),
    );
  }
}