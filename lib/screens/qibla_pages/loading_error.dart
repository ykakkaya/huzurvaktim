import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LocationErrorWidget extends StatelessWidget {
  final String? error;
  final Function? callback;

  const LocationErrorWidget({Key? key, this.error, this.callback}) : super(key: key);

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
          const Text(
            "qiblaLoadingError",
            style: TextStyle(color: errorColor, fontWeight: FontWeight.bold),
          ).tr(),
          box,
          ElevatedButton(
            onPressed: callback != null ? () => callback!() : null,
            child: const Text("qiblaLoadingErrorButton").tr(),
          ),
        ],
      ),
    );
  }
}
