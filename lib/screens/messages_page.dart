import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:huzurvakti/screens/image_swiper_page.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CategoryCard(
            title: 'Cuma Mesajları',
            subtitle: 'Hayırlı cumalar dileyin',
            icon: Icons.mosque_rounded,
            gradientColors: const [Color(0xFF0D47A1), Color(0xFF1976D2)],
            assetFolder: 'assets/images/cuma/',
          ),
          const SizedBox(height: 24),
          _CategoryCard(
            title: 'Kandil & Bayram Mesajları',
            subtitle: 'Mübarek günleri kutlayın',
            icon: Icons.auto_awesome_rounded,
            gradientColors: const [Color(0xFF1B5E20), Color(0xFF388E3C)],
            assetFolder: 'assets/images/kandil-bayram/',
          ),
          const SizedBox(height: 24),
          _CategoryCard(
            title: 'Özel Günler',
            subtitle: 'Milli ve özel günleri paylaşın',
            icon: Icons.celebration_rounded,
            gradientColors: const [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
            assetFolder: 'assets/images/genel/',
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String assetFolder;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.assetFolder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageSwiperPage(
              title: title,
              assetFolder: assetFolder,
            ),
          ),
        );
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -24,
              bottom: -24,
              child: Icon(
                icon,
                size: 150,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.philosopher(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
