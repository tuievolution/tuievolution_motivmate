import 'dart:async';
import 'dart:ui'; 

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as ads;
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'app_state.dart';
import 'models/theme_presets.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ads.MobileAds.instance.initialize();
  
  runApp(const MotivMoodRoot());
}

class MotivMoodRoot extends StatefulWidget {
  const MotivMoodRoot({super.key});

  @override
  State<MotivMoodRoot> createState() => _MotivMoodRootState();
}

class _MotivMoodRootState extends State<MotivMoodRoot> {
  AppState? _appState;

  @override
  Widget build(BuildContext context) {
    if (_appState == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MotivMood Yükleniyor',
        home: SplashScreen(
          onInitializationComplete: (initializedState) {
            setState(() {
              _appState = initializedState;
            });
          },
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _appState!,
      child: const MotivMoodMainApp(),
    );
  }
}

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
      home: Material(
        type: MaterialType.transparency,
        child: StreamBuilder<List<ConnectivityResult>>(
          stream: Connectivity().onConnectivityChanged,
          builder: (context, snapshot) {
            final isChecking = snapshot.connectionState == ConnectionState.waiting;
            final results = snapshot.data ?? [];
            final isOffline = !isChecking && (results.contains(ConnectivityResult.none) || results.isEmpty);

            return Stack(
              children: [
                const HomeScreen(),

                if (isOffline)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            border: const Border(top: BorderSide(color: Colors.white24, width: 1)),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Row(
                              children: [
                                const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 28),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    appState.settings.appLanguage == 'en' ? 'No Internet Connection' : 'İnternet Bağlantısı Yok',
                                    style: const TextStyle(
                                      color: Colors.white, 
                                      fontSize: 15, 
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}