import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:huzurvakti/utils/project_colors.dart';

class ImageSwiperPage extends StatefulWidget {
  final String title;
  final String assetFolder;

  const ImageSwiperPage({
    super.key,
    required this.title,
    required this.assetFolder,
  });

  @override
  State<ImageSwiperPage> createState() => _ImageSwiperPageState();
}

class _ImageSwiperPageState extends State<ImageSwiperPage> {
  final CardSwiperController _controller = CardSwiperController();
  final GlobalKey _shareButtonKey = GlobalKey();
  List<String> _imagePaths = [];
  int _currentIndex = 0;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final manifest = await AssetManifest.loadFromAssetBundle(
      DefaultAssetBundle.of(context),
    );
    final paths = manifest
        .listAssets()
        .where((key) => key.startsWith(widget.assetFolder))
        .toList()
      ..shuffle();
    setState(() => _imagePaths = paths);
  }

  Future<void> _shareCurrentImage() async {
    if (_imagePaths.isEmpty || _isSharing) return;
    final idx = _currentIndex.clamp(0, _imagePaths.length - 1);
    setState(() => _isSharing = true);
    try {
      final ByteData data = await rootBundle.load(_imagePaths[idx]);
      final Uint8List bytes = data.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/shared_image.png');
      await file.writeAsBytes(bytes);
      final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: origin,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProjectColor.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.title,
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
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _imagePaths.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: CardSwiper(
                      controller: _controller,
                      cardsCount: _imagePaths.length,
                      onSwipe: (previousIndex, currentIndex, direction) {
                        if (currentIndex != null) {
                          setState(() => _currentIndex = currentIndex);
                        }
                        return true;
                      },
                      numberOfCardsDisplayed:
                          _imagePaths.length >= 3 ? 3 : _imagePaths.length,
                      backCardOffset: const Offset(0, 28),
                      padding: EdgeInsets.zero,
                      cardBuilder: (context, index, h, v) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                _imagePaths[index],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.swipe_rounded,
                        color: Colors.grey[400],
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kaydırarak geçin',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32, top: 4),
                  child: ElevatedButton.icon(
                    key: _shareButtonKey,
                    onPressed: _isSharing ? null : _shareCurrentImage,
                    icon: _isSharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.share_rounded),
                    label: Text(
                      _isSharing ? 'Paylaşılıyor...' : 'Paylaş',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProjectColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
