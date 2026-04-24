import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huzurvakti/providers/hadith_provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:huzurvakti/utils/project_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class HadithPage extends ConsumerStatefulWidget {
  const HadithPage({super.key});

  @override
  ConsumerState<HadithPage> createState() => _HadithPageState();
}

class _HadithPageState extends ConsumerState<HadithPage> {
  bool _isBack = true;
  double _angle = 0;
  final _repaintKey = GlobalKey();

  void _flip() {
    // Ön yüzden arka yüze geçerken yeni hadis yükle
    final goingToBack = (_angle % (2 * pi)) < (pi / 2) || (_angle % (2 * pi)) >= (3 * pi / 2);
    if (goingToBack) {
      ref.read(hadithProvider.notifier).refresh();
    }
    setState(() {
      _angle = (_angle + pi) % (2 * pi);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hadithProvider);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Kart animasyonu
            GestureDetector(
              onTap: _flip,
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: _angle),
                duration: const Duration(milliseconds: 600),
                builder: (BuildContext context, double val, __) {
                  if (val >= (pi / 2)) {
                    _isBack = false;
                  } else {
                    _isBack = true;
                  }
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(val),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.95,
                      height: MediaQuery.of(context).size.height * 0.70,
                      child: _isBack
                          ? _buildFrontCard()
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: RepaintBoundary(
                                key: _repaintKey,
                                child: _buildBackCard(state),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            if (!state.isLoading &&
                state.items.isNotEmpty &&
                (_angle % (2 * pi)) >= (pi / 2) &&
                (_angle % (2 * pi)) < (3 * pi / 2))
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _shareCardAsImage(),
                    icon: const Icon(Icons.share_rounded, size: 28),
                    color: ProjectColor.primary,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareCardAsImage() async {
    final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/hadith_share.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
    ));
  }

  Widget _buildFrontCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        image: const DecorationImage(
          fit: BoxFit.fill,
          image: AssetImage('assets/images/question.png'),
        ),
      ),
    );
  }

  Widget _buildBackCard(HadithState state) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        image: const DecorationImage(
          fit: BoxFit.fill,
          image: AssetImage('assets/images/back.png'),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 35, 15, 10),
          child: _buildHadithContent(state),
        ),
      ),
    );
  }

  Widget _buildHadithContent(HadithState state) {
    // Yükleniyor
    if (state.isLoading) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    // Hata
    if (state.error != null) {
      return Text(
        context.tr('defaultHadith'),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
      );
    }

    // Liste boş
    if (state.items.isEmpty ||
        state.index < 0 ||
        state.index >= state.items.length) {
      return Html(
        data: context.tr('defaultHadith'),
        style: {
          'body': Style(
            fontSize: FontSize(18),
            color: ProjectColor.hadithTextColor,
            textAlign: TextAlign.center,
          ),
        },
      );
    }

    // Normal hadis gösterimi
    final turkce = state.items[state.index]['turkce'];
    final textToShow = turkce != null ? turkce.toString() : '';
    return Html(
      data: textToShow,
      style: {
        'body': Style(
          fontSize: FontSize(16),
          color: ProjectColor.hadithTextColor,
          textAlign: TextAlign.center,
        ),
      },
    );
  }
}
