import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:huzurvakti/providers/quran_provider.dart';
import 'package:huzurvakti/models/sure.dart';
import 'package:huzurvakti/models/ayet.dart';
import 'package:huzurvakti/utils/project_colors.dart';
import 'package:share_plus/share_plus.dart';

class QuranDetailPage extends ConsumerWidget {
  final Sure sure;
  const QuranDetailPage({super.key, required this.sure});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quranProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) =>
          ref.read(quranProvider.notifier).clearSelectedSure(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context, ref),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ayet = state.ayetList[index];
                    return _buildAyetCard(ayet, index + 1);
                  },
                  childCount: state.ayetList.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: ProjectColor.primaryDark,
      leading: IconButton(
        onPressed: () => ref.read(quranProvider.notifier).clearSelectedSure(),
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient arka plan
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0277BD),
                    Color(0xFF0288D1),
                    Color(0xFF039BE5),
                  ],
                ),
              ),
            ),
            // Dekoratif daire
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // İçerik
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    sure.isimAr ?? "",
                    style: GoogleFonts.amiri(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sure.isim ?? '',
                    style: GoogleFonts.philosopher(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge(Icons.location_on_outlined, sure.yer ?? ""),
                      const SizedBox(width: 10),
                      _buildBadge(Icons.format_list_numbered, "${sure.ayetSayisi} Ayet"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyetCard(Ayet ayet, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0288D1).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kart başlık satırı
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                // Ayet numarası - modern altıgen/rozet tarzı
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0288D1), Color(0xFF03A9F4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Paylaş butonu
                Material(
                  color: Colors.transparent,
                  child: Builder(
                    builder: (btnCtx) => InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        final shareText =
                            "${sure.isim} - $number. Ayet\n\n${ayet.textAr}\n\n${ayet.text}";
                        final box = btnCtx.findRenderObject() as RenderBox?;
                        final shareRect = box != null
                            ? box.localToGlobal(Offset.zero) & box.size
                            : null;
                        SharePlus.instance.share(ShareParams(
                          text: shareText,
                          sharePositionOrigin: shareRect,
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.ios_share_rounded,
                          size: 18,
                          color: Color(0xFF0288D1),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // İnce ayraç
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFFE8F4FD),
          ),

          // Ayet içeriği
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Arapça metin
                Text(
                  ayet.textAr ?? "",
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiri(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 2.0,
                    color: const Color(0xFF1A237E),
                  ),
                ),

                const SizedBox(height: 16),

                // Türkçe metin - soluk mavi arka planlı kutu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    ayet.text ?? "",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF37474F),
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
