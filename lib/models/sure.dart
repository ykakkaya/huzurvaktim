class Sure {
  Sure({
    required this.aciklama,
    required this.ayetSayisi,
    required this.cuz,
    required this.isim,
    required this.isimAr,
    required this.sayfa,
    required this.sure,
    required this.yer,
  });

  final String? aciklama;
  final int? ayetSayisi;
  final int? cuz;
  final String? isim;
  final String? isimAr;
  final int? sayfa;
  final int? sure;
  final String? yer;

  factory Sure.fromJson(Map<String, dynamic> json){
    return Sure(
      aciklama: json["aciklama"],
      ayetSayisi: json["ayet_sayisi"],
      cuz: json["cuz"],
      isim: json["isim"],
      isimAr: json["isim_ar"],
      sayfa: json["sayfa"],
      sure: json["sure"],
      yer: json["yer"],
    );
  }

  Map<String, dynamic> toJson() => {
    "aciklama": aciklama,
    "ayet_sayisi": ayetSayisi,
    "cuz": cuz,
    "isim": isim,
    "isim_ar": isimAr,
    "sayfa": sayfa,
    "sure": sure,
    "yer": yer,
  };

}
