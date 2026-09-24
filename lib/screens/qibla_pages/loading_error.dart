import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LocationErrorWidget extends StatelessWidget {
  final String? error;
  final FutureOr<void> Function()? callback;

  const LocationErrorWidget({super.key, this.error, this.callback});

  @override
  Widget build(BuildContext context) {
    const box = SizedBox(height: 32);
    const errorColor = Color(0xffb00020);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.location_off, size: 150, color: errorColor),
          box,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error ?? 'qiblaLoadingError'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          box,
          ElevatedButton(
            onPressed: callback,
            child: const Text("qiblaLoadingErrorButton").tr(),
          ),
        ],
      ),
    );
  }
}
