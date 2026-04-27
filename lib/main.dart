import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huzurvakti/providers/shared_prefs_provider.dart';
import 'package:huzurvakti/service/notification_service.dart';
import 'package:huzurvakti/service/background_task.dart';
import 'package:huzurvakti/providers/home_provider.dart';
import 'package:huzurvakti/screens/hadith_page.dart';
import 'package:huzurvakti/screens/prayer_page.dart';
import 'package:huzurvakti/screens/qibla_pages/qibla_page.dart';
import 'package:huzurvakti/screens/quran_page.dart';
import 'package:huzurvakti/screens/zikr_page.dart';
import 'package:huzurvakti/screens/messages_page.dart';
import 'package:huzurvakti/utils/project_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:upgrader/upgrader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Google Fonts'un runtime'da network isteği yapmasını engelle
  // Fontlar pubspec.yaml assets olarak tanımlanmalı
  GoogleFonts.config.allowRuntimeFetching = false;

  await EasyLocalization.ensureInitialized();
  await NotificationService.init();
  await BackgroundTask.init();
  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('en', 'US'), Locale('tr', 'TR')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.deviceLocale,
      title: "Huzur Vakti",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: UpgradeAlert(
        upgrader: Upgrader(
          messages: _UpgraderTr(),
          durationUntilAlertAgain: const Duration(days: 1),
          countryCode: 'tr',
          languageCode: 'tr',
          debugLogging: kDebugMode,
        ),
        dialogStyle: UpgradeDialogStyle.material,
        child: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage>
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
    if (state == AppLifecycleState.resumed) {
      BackgroundTask.registerNext();
    }
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0: return "Kur'an-ı Kerim";
      case 1: return "Kıble Bulucu";
      case 2: return "Zikirmatik";
      case 3: return "Namaz Vakitleri";
      case 4: return "Günün Hadisi";
      case 5: return "Mesajlar";
      default: return "Huzur Vakti";
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentIndexProvider);
    
    return Scaffold(
      backgroundColor: ProjectColor.backgroundColor,
      appBar: (currentIndex == 0 || currentIndex == 3)
        ? null
        : AppBar(
            title: Text(
              _getAppBarTitle(currentIndex),
              style: GoogleFonts.philosopher(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
            backgroundColor: ProjectColor.appbarColor,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
          ),
      body: _getPage(currentIndex),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: ProjectColor.bottomBar,
          selectedItemColor: ProjectColor.bottomBarActivaColor,
          unselectedItemColor: ProjectColor.bottomBarInActiveColor,
          currentIndex: currentIndex,
          onTap: (index) => ref.read(currentIndexProvider.notifier).state = index,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          iconSize: 28,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.fingerprint_rounded), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.access_time_filled_rounded), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.format_quote_rounded), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.card_giftcard_rounded), label: ''),
          ],
        ),
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const QuranPage();
      case 1:
        return const QiblahCompass();

      case 2:
        return const ZikrPage();
      case 3:
        return const PrayerTimesPage();
      case 4:
        return const HadithPage();
      case 5:
        return const MessagesPage();
      default:
        return const QuranPage();
    }
  }
}

class _UpgraderTr extends UpgraderMessages {
  @override
  String get title => 'Güncelleme Mevcut';

  @override
  String get body =>
      '{{appName}} uygulamasının yeni bir sürümü ({{currentAppStoreVersion}}) mevcut. '
      'Şu an {{currentInstalledVersion}} sürümünü kullanıyorsunuz.';

  @override
  String get prompt => 'Şimdi güncellemek ister misiniz?';

  @override
  String get buttonTitleUpdate => 'Güncelle';

  @override
  String get buttonTitleLater => 'Sonra';

  @override
  String get buttonTitleIgnore => 'Yoksay';

  @override
  String get releaseNotes => 'Yenilikler';
}
