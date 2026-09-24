import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';

import 'package:huzurvakti/screens/qibla_pages/loading_error.dart';
import 'package:huzurvakti/screens/qibla_pages/loading_indicator.dart';
import 'package:huzurvakti/service/qibla_stream_service.dart';
import 'package:huzurvakti/utils/project_colors.dart';

// Basit konum izin durumu modeli (flutter_qiblah bağımlılığı olmadan)
typedef _LocStatus = ({bool enabled, LocationPermission permission});

class QiblahCompass extends StatefulWidget {
  const QiblahCompass({super.key});

  @override
  State<QiblahCompass> createState() => _QiblahCompassState();
}

class _QiblahCompassState extends State<QiblahCompass>
    with WidgetsBindingObserver {
  late Future<_LocStatus> _locationStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationStatus = _loadLocationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLocationStatus();
    }
  }

  Future<_LocStatus> _loadLocationStatus() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    var permission = await Geolocator.checkPermission();

    if (enabled && permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return (enabled: enabled, permission: permission);
  }

  void _refreshLocationStatus() {
    if (!mounted) return;
    setState(() {
      _locationStatus = _loadLocationStatus();
    });
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
    _refreshLocationStatus();
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
    _refreshLocationStatus();
  }

  Future<void> _requestPermissionAgain() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      await _openAppSettings();
    } else {
      _refreshLocationStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ProjectColor.backgroundColor,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<_LocStatus>(
        future: _locationStatus,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return LocationErrorWidget(
              error: 'Konum servisi hatası: ${snapshot.error}',
              callback: _refreshLocationStatus,
            );
          }

          final loc = snapshot.data;
          if (loc == null) return const LoadingIndicator();

          if (!loc.enabled) {
            return LocationErrorWidget(
              error: 'Konum servisi kapalı.\nLütfen GPS\'i açın.',
              callback: _openLocationSettings,
            );
          }

          switch (loc.permission) {
            case LocationPermission.always:
            case LocationPermission.whileInUse:
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Expanded(child: QiblahCompassWidget())],
              );
            case LocationPermission.denied:
              return LocationErrorWidget(
                error: 'Konum izni reddedildi.',
                callback: _requestPermissionAgain,
              );
            case LocationPermission.deniedForever:
              return LocationErrorWidget(
                error:
                    'Konum izni kalıcı olarak reddedildi.\nUygulama ayarlarından izin verin.',
                callback: _openAppSettings,
              );
            default:
              return const SizedBox();
          }
        },
      ),
    );
  }
}

class QiblahCompassWidget extends StatefulWidget {
  const QiblahCompassWidget({super.key});

  @override
  State<QiblahCompassWidget> createState() => _QiblahCompassWidgetState();
}

class _QiblahCompassWidgetState extends State<QiblahCompassWidget> {
  final _compassSvg = SvgPicture.asset('assets/images/compass.svg');
  final _needleSvg = SvgPicture.asset(
    'assets/images/needle.svg',
    fit: BoxFit.contain,
    height: 300,
    alignment: Alignment.center,
  );

  QiblaStreamService? _service;
  Stream<QiblaData>? _stream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    _service?.dispose();
    _service = QiblaStreamService();
    setState(() {
      _stream = _service!.createStream();
    });
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_stream == null) return const LoadingIndicator();

    return StreamBuilder<QiblaData>(
      stream: _stream,
      builder: (_, AsyncSnapshot<QiblaData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (snapshot.hasError) {
          return LocationErrorWidget(
            error: 'Pusula sensörü kullanılamıyor.\n${snapshot.error}',
            callback: _initStream,
          );
        }
        if (snapshot.data == null) return const LoadingIndicator();

        final data = snapshot.data!;

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: (data.direction * (pi / 180) * -1),
              child: _compassSvg,
            ),
            Transform.rotate(
              angle: (data.qiblah * (pi / 180) * -1),
              alignment: Alignment.center,
              child: _needleSvg,
            ),
          ],
        );
      },
    );
  }
}
