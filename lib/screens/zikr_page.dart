import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huzurvakti/providers/zikr_provider.dart';

import 'package:huzurvakti/utils/project_colors.dart';
import 'package:easy_localization/easy_localization.dart';

class ZikrPage extends ConsumerWidget {
  const ZikrPage({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(zikrProvider);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/images/zikirmatik.png', width: 300),
                Positioned(
                  top: 46,
                  right: 80,
                  child: Text(
                    counter.toString(),
                    style: TextStyle(
                      fontFamily: 'Digital7',
                      fontSize: 50,
                      color: ProjectColor.zikrTextColor,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  child: GestureDetector(
                    onTap: () => ref.read(zikrProvider.notifier).increment(),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 76,
                  bottom: 114,
                  child: GestureDetector(
                    onTap: () => _showResetDialog(context, ref),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.1,
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr("zikrDeleteTitle")),
        content: Text(context.tr("zikrDeleteText")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr("zikrDeleteCancel")),
          ),
          TextButton(
            onPressed: () {
              ref.read(zikrProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: Text(context.tr("zikrDeleteConfirm")),
          ),
        ],
      ),
    );
  }
}
