import 'dart:async';
import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';


import 'package:huzurvakti/screens/qibla_pages/loading_error.dart';
import 'package:huzurvakti/screens/qibla_pages/loading_indicator.dart';

import 'package:huzurvakti/utils/project_colors.dart';

class QiblahCompass extends StatefulWidget {
  const QiblahCompass({super.key});

  @override
  _QiblahCompassState createState() => _QiblahCompassState();
}

class _QiblahCompassState extends State<QiblahCompass> {
  final _locationStreamController =
      StreamController<LocationStatus>.broadcast();

  Stream<LocationStatus> get stream => _locationStreamController.stream;

  bool _deviceSupportSensor = true;

  @override
  void initState() {
    super.initState();
    _initQiblah();
  }

  Future<void> _initQiblah() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final support = await FlutterQiblah.androidDeviceSensorSupport();
        if (mounted) {
          setState(() {
            _deviceSupportSensor = support ?? false;
          });
        }
        if (_deviceSupportSensor) {
          _checkLocationStatus();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _deviceSupportSensor = false;
          });
        }
      }
    } else {
      _checkLocationStatus();
    }
  }

  @override
  void dispose() {
    _locationStreamController.close();
    FlutterQiblah().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_deviceSupportSensor) {
      return Container(
        color: ProjectColor.backgroundColor,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16.0),
        child: const Center(
          child: Text(
            "Bu cihazda pusula sensörü (magnetometer) bulunmuyor.\nKıble yönü belirlenemiyor.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      color: ProjectColor.backgroundColor,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8.0),
      child: StreamBuilder(
        stream: stream,
        builder: (context, AsyncSnapshot<LocationStatus> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return LocationErrorWidget(
              error: snapshot.error.toString(),
              callback: _checkLocationStatus,
            );
          }
          if (snapshot.data?.enabled == true) {
            switch (snapshot.data!.status) {
              case LocationPermission.always:
              case LocationPermission.whileInUse:
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: QiblahCompassWidget()),
                  ],
                );

              case LocationPermission.denied:
                return LocationErrorWidget(
                  error: "Location service permission denied",
                  callback: _checkLocationStatus,
                );
              case LocationPermission.deniedForever:
                return LocationErrorWidget(
                  error: "Location service Denied Forever !",
                  callback: _checkLocationStatus,
                );
              // case GeolocationStatus.unknown:
              //   return LocationErrorWidget(
              //     error: "Unknown Location service error",
              //     callback: _checkLocationStatus,
              //   );
              default:
                return const SizedBox();
            }
          } else {
            return LocationErrorWidget(
              error: "Please enable Location service",
              callback: _checkLocationStatus,
            );
          }
        },
      ),
    );
  }

  Future<void> _checkLocationStatus() async {
    try {
      final locationStatus = await FlutterQiblah.checkLocationStatus();
      if (locationStatus.enabled &&
          locationStatus.status == LocationPermission.denied) {
        await FlutterQiblah.requestPermissions();
        final s = await FlutterQiblah.checkLocationStatus();
        if (mounted) {
          _locationStreamController.sink.add(s);
        }
      } else {
        if (mounted) {
          _locationStreamController.sink.add(locationStatus);
        }
      }
    } catch (e) {
      if (mounted) {
        _locationStreamController.sink.addError('Konum servisi hatası: ${e.toString()}');
      }
    }
  }
}

class QiblahCompassWidget extends StatelessWidget {
  final _compassSvg = SvgPicture.asset('assets/images/compass.svg');
  final _needleSvg = SvgPicture.asset(
    'assets/images/needle.svg',
    fit: BoxFit.contain,
    height: 300,
    alignment: Alignment.center,
  );

  QiblahCompassWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FlutterQiblah.qiblahStream,
      builder: (_, AsyncSnapshot<QiblahDirection> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (snapshot.hasError) {
          return LocationErrorWidget(
            error: "Pusula sensörü kullanılamıyor.\n(Not: Bazı cihazlarda magnetometer sensörü bulunmayabilir)",
            callback: () {
              // Retry loading
            },
          );
        }

        if (snapshot.data == null) {
          return const LoadingIndicator();
        }

        final qiblahDirection = snapshot.data!;

        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.rotate(
              angle: (qiblahDirection.direction * (pi / 180) * -1),
              child: _compassSvg,
            ),
            Transform.rotate(
              angle: (qiblahDirection.qiblah * (pi / 180) * -1),
              alignment: Alignment.center,
              child: _needleSvg,
            ),
          ],
        );
      },
    );
  }
}
