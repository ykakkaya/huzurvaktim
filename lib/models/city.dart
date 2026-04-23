class City {
  City({
    required this.sehirAdi,
    required this.sehirAdiEn,
    required this.sehirId,
    required this.ulkeId
  });

  final String? sehirAdi;
  final String? sehirAdiEn;
  final int sehirId;
  final int ulkeId;

  factory City.fromJson(Map<String, dynamic> json){
    return City(
      sehirAdi: json["SehirAdi"],
      sehirAdiEn: json["SehirAdiEn"],
      sehirId: int.parse(json["SehirID"].toString()),
      ulkeId: int.parse(json["ulkeId"].toString())
    );
  }

  Map<String, dynamic> toJson() => {
    "SehirAdi": sehirAdi,
    "SehirAdiEn": sehirAdiEn,
    "SehirID": sehirId,
    "ulkeId": ulkeId
  };
}
