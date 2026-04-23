import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huzurvakti/providers/shared_prefs_provider.dart';

class ZikrNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('counter') ?? 0;
  }

  void increment() {
    state++;
    ref.read(sharedPreferencesProvider).setInt('counter', state);
  }

  void reset() {
    state = 0;
    ref.read(sharedPreferencesProvider).setInt('counter', state);
  }
}

final zikrProvider = NotifierProvider<ZikrNotifier, int>(ZikrNotifier.new);
