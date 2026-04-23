import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clockProvider = StreamProvider<String>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  });
});
