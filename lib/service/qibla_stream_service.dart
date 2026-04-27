import 'dart:async';
import 'dart:math';

import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:geolocator/geolocator.dart';

class QiblaData {
  final double qiblah;
  final double direction;
  const QiblaData({required this.qiblah, required this.direction});
}

class QiblaStreamService {
  StreamController<QiblaData>? _controller;
  StreamSubscription<CompassEvent>? _compassSub;

  Stream<QiblaData> createStream() {
    _controller = StreamController<QiblaData>.broadcast(onCancel: _cleanup);
    _start();
    return _controller!.stream;
  }

  Future<void> _start() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final offset = _bearingToKaaba(position.latitude, position.longitude);

      final events = FlutterCompass.events;
      if (events == null) {
        _controller?.addError('Pusula sensörü bu cihazda kullanılamıyor.');
        return;
      }

      _compassSub = events.listen(
        (event) {
          final heading = event.heading;
          if (heading == null) return;
          if (_controller == null || _controller!.isClosed) return;
          _controller!.add(QiblaData(
            qiblah: heading + (360 - offset),
            direction: heading,
          ));
        },
        onError: (e) => _controller?.addError(e),
        cancelOnError: false,
      );
    } on TimeoutException {
      _controller?.addError(
        'Konum alınamadı (zaman aşımı).\nLütfen GPS\'i açık konuma getirin.',
      );
    } catch (e) {
      _controller?.addError('Konum hatası: $e');
    }
  }

  /// Küresel trigonometri ile mevcut koordinattan Kaabe'ye olan bearing hesabı.
  static double _bearingToKaaba(double lat, double lng) {
    const kaabaLat = 21.4225 * (pi / 180);
    const kaabaLng = 39.8262 * (pi / 180);
    final latRad = lat * (pi / 180);
    final lngRad = lng * (pi / 180);
    final y = sin(kaabaLng - lngRad);
    final x =
        cos(latRad) * tan(kaabaLat) - sin(latRad) * cos(kaabaLng - lngRad);
    return (atan2(y, x) * (180 / pi) + 360) % 360;
  }

  void _cleanup() {
    _compassSub?.cancel();
    _compassSub = null;
  }

  void dispose() {
    _cleanup();
    if (_controller != null && !_controller!.isClosed) {
      _controller!.close();
    }
    _controller = null;
  }
}
