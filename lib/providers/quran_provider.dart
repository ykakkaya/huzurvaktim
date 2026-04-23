import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/kuranikerim/Kuranikerim_data.dart';
import '../models/ayet.dart';
import '../models/sure.dart';

class QuranState {
  final List<Sure> sureList;
  final List<Ayet> ayetList;
  final int selectedSure;
  final Sure? selectedSureObj;

  QuranState({
    required this.sureList,
    required this.ayetList,
    required this.selectedSure,
    this.selectedSureObj,
  });

  QuranState copyWith({
    List<Sure>? sureList,
    List<Ayet>? ayetList,
    int? selectedSure,
    Sure? selectedSureObj,
    bool clearSureObj = false,
  }) {
    return QuranState(
      sureList: sureList ?? this.sureList,
      ayetList: ayetList ?? this.ayetList,
      selectedSure: selectedSure ?? this.selectedSure,
      selectedSureObj: clearSureObj ? null : (selectedSureObj ?? this.selectedSureObj),
    );
  }
}

class QuranNotifier extends Notifier<QuranState> {
  final databaseManager = KuraniKerimDatabeManager();

  @override
  QuranState build() {
    _init();
    return QuranState(sureList: [], ayetList: [], selectedSure: 0);
  }

  Future<void> _init() async {
    await databaseManager.createData();
    final sureList = await databaseManager.getSureList();
    state = state.copyWith(sureList: sureList);
    if (state.selectedSure > 0) {
      await getAyetList(state.selectedSure);
    }
  }

  Future<void> getAyetList(int sureId, {Sure? sureObj}) async {
    final ayetList = await databaseManager.getAyetsBySure(sureId);
    state = state.copyWith(ayetList: ayetList, selectedSure: sureId, selectedSureObj: sureObj);
  }

  void clearSelectedSure() {
    state = state.copyWith(clearSureObj: true);
  }
}

final quranProvider = NotifierProvider<QuranNotifier, QuranState>(QuranNotifier.new);
