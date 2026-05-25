import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:multiads/multiads.dart';

import 'app_messenger.dart';
import 'config/app_product_info.dart';
import 'screens/splash_screen.dart';
import 'services/ads_actions.dart';
import 'theme/app_colors.dart';
import 'util/global.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var url = Uri.parse(
    "https://drive.google.com/uc?export=download&id=1_pKdpoiyensy_jO5wMK2e3lSI3b_qHBm",
  );
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      gAds = MultiAds(
        response.body,
        config: MultiAdsConfig(
          admobTestDeviceIds: ['79738754EC81FA5F64972928128B2FFF'],
          facebookTestingId: 'd1a0df1f-2528-4e41-a4d3-1b401ba14f7d',
          enableLogs: true, // set false before release
        ),
      );
      gAdsReady = true;
      await gAds.init();
      await gAds.loadAds();
    }
  } catch (_) {
    // Ads config unavailable; app still launches without ads.
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        recordAppBackgrounded();
      case AppLifecycleState.resumed:
        showAppOpenOnResumeIfEligible();
      case AppLifecycleState.detached:
        break;
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
