import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huzurvakti/main.dart';
import 'package:huzurvakti/providers/quran_provider.dart';
import 'package:huzurvakti/providers/shared_prefs_provider.dart';
import 'package:huzurvakti/screens/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ana ekran sorunsuz acilir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          // Testte SQLite acmadan ana ekranin cizilmesini dogrula.
          quranProvider.overrideWithBuild(
            (ref, notifier) => QuranState(
              sureList: const [],
              ayetList: const [],
              selectedSure: 0,
            ),
          ),
        ],
        child: const MaterialApp(home: MyHomePage()),
      ),
    );
    await tester.pump();

    expect(find.text("Kur'an-ı Kerim"), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding tamamlanabilir', (tester) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          onComplete: () async {
            completed = true;
          },
        ),
      ),
    );

    expect(find.text('Vakitler hep yanında'), findsOneWidget);

    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    expect(find.text('Kıbleyi kolayca bul'), findsOneWidget);

    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    expect(find.text('Maneviyatın tek yerde'), findsOneWidget);

    await tester.tap(find.text('Başlayalım'));
    await tester.pump();
    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
