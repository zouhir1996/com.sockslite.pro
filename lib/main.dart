import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ads/admob_bootstrap.dart';
import 'ads/admob_config.dart';
import 'ads/admob_remote_loader.dart';
import 'ads/admob_sdk.dart';
import 'ads/app_open_ad_manager.dart';
import 'app_messenger.dart';
import 'config/app_product_info.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  if (!kIsWeb) {
    await AdMobRemoteLoader.instance.load();
    await AdMobSdk.ensureInitialized();
    await AdMobBootstrap.warmUp();
  }
  runApp(const SocksliteApp());
}

class SocksliteApp extends StatefulWidget {
  const SocksliteApp({super.key});

  @override
  State<SocksliteApp> createState() => _SocksliteAppState();
}

class _SocksliteAppState extends State<SocksliteApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && AdMobConfig.appOpenActive) {
      WidgetsBinding.instance.addObserver(this);
      AppOpenAdManager.instance.scheduleColdStartShow();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && AdMobConfig.appOpenActive) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb && AdMobConfig.appOpenActive) {
      AppOpenAdManager.instance.handleLifecycle(state);
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: AppProductInfo.name,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppMessenger.scaffoldMessengerKey,
      theme: base.copyWith(
        scaffoldBackgroundColor: AppColors.scaffoldBlack,
        colorScheme: base.colorScheme.copyWith(
          primary: AppColors.accentBlue,
          surface: AppColors.cardGrey,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
      ),
      home: const SplashScreen(),
    );
  }
}
