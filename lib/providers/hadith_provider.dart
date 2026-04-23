import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HadithState {
  final List<dynamic> items;
  final int index;
  final bool isLoading;
  final String? error;

  HadithState({
    required this.items,
    required this.index,
    this.isLoading = true,
    this.error,
  });

  HadithState copyWith({
    List<dynamic>? items,
    int? index,
    bool? isLoading,
    String? error,
  }) {
    return HadithState(
      items: items ?? this.items,
      index: index ?? this.index,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class HadithNotifier extends Notifier<HadithState> {
  @override
  HadithState build() {
    _init();
    return HadithState(items: [], index: 0, isLoading: true);
  }

  Future<void> _init() async {
    try {
      final String response = await rootBundle.loadString('assets/data.json');
      // json.decode senkron — await gereksiz ama zararsız
      final data = json.decode(response) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;
      if (items.isEmpty) return;
      final index = Random().nextInt(items.length);
      state = state.copyWith(items: items, index: index, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Yeni random hadis getir
  void refresh() {
    if (state.items.isEmpty) return;
    final newIndex = Random().nextInt(state.items.length);
    state = state.copyWith(index: newIndex);
  }
}

final hadithProvider =
    NotifierProvider<HadithNotifier, HadithState>(HadithNotifier.new);
