import 'package:flutter/material.dart';
import 'package:huzurvakti/utils/project_colors.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: ProjectColor.primary),
      );
}
