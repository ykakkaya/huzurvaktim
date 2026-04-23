import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:huzurvakti/providers/quran_provider.dart';
import 'package:huzurvakti/screens/quran_detail.dart';
import 'package:huzurvakti/utils/project_colors.dart';
import '../models/sure.dart';

// Fontlar main() içinde preload edildiği için burada static tanımlama güvenli
final _titleStyle = GoogleFonts.poppins(
  fontSize: 17,
  fontWeight: FontWeight.w600,
  color: ProjectColor.textPrimary,
);
final _subtitleStyle = GoogleFonts.poppins(
  fontSize: 12,
  color: ProjectColor.textSecondary,
);
final _arabicStyle = GoogleFonts.amiri(
  fontSize: 21,
  fontWeight: FontWeight.bold,
  color: ProjectColor.primary,
);
final _numberStyle = GoogleFonts.philosopher(
  fontSize: 15,
  fontWeight: FontWeight.bold,
  color: ProjectColor.primary,
);
final _appBarTitleStyle = GoogleFonts.philosopher(
  color: ProjectColor.textOnPrimary,
  fontWeight: FontWeight.bold,
);

class QuranPage extends ConsumerWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quranProvider);
    final notifier = ref.read(quranProvider.notifier);

    if (state.selectedSureObj != null) {
      return QuranDetailPage(sure: state.selectedSureObj!);
    }

    // Scaffold burada zorunlu — SliverAppBar koordinat sistemini buradan alır
    return Scaffold(
      backgroundColor: ProjectColor.backgroundColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: ProjectColor.appbarColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text("Kur'an-ı Kerim", style: _appBarTitleStyle),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/kk.png',
                    fit: BoxFit.cover,
                    cacheHeight: 400,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC0288D1)], // primaryDark
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.sureList.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _SurahItem(
                    key: ValueKey(index),
                    index: index,
                    sure: state.sureList[index],
                    notifier: notifier,
                  ),
                  childCount: state.sureList.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SurahItem extends StatelessWidget {
  final int index;
  final Sure sure;
  final QuranNotifier notifier;

  const _SurahItem({
    super.key,
    required this.index,
    required this.sure,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        shadowColor: const Color(0x1A000000),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => notifier.getAyetList(sure.sure!, sureObj: sure),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _SurahNumber(number: index + 1),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(sure.isim ?? "", style: _titleStyle),
                      Text(
                        "${sure.yer} • ${sure.ayetSayisi} Ayet",
                        style: _subtitleStyle,
                      ),
                    ],
                  ),
                ),
                Text(sure.isimAr ?? "", style: _arabicStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahNumber extends StatelessWidget {
  final int number;
  const _SurahNumber({required this.number});

  static const _decoration = BoxDecoration(
    shape: BoxShape.circle,
    color: Color(0x1403A9F4), // primary %8 opasite
    border: Border.fromBorderSide(
      BorderSide(color: Color(0x4D03A9F4), width: 1), // primary %30
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: _decoration,
      child: Center(
        child: Text(number.toString(), style: _numberStyle),
      ),
    );
  }
}
